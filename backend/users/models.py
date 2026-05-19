from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import F, Q
from django.utils import timezone


# Extiende el modelo de usuario por defecto de Django.
# Agrega el campo 'role' para distinguir entre atletas y coaches.
class User(AbstractUser):
    ROLE_CHOICES = (
        ("athlete", "Athlete"),
        ("coach", "Coach"),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)

    # Sobreescribe el email para hacerlo único — no puede haber dos usuarios con el mismo email.
    email = models.EmailField(unique=True)
    age = models.IntegerField(null=True, blank=True)
    height = models.FloatField(null=True, blank=True)
    weight = models.FloatField(null=True, blank=True)
    training_goal = models.CharField(max_length=30, blank=True, default="")
    timezone = models.CharField(
        max_length=50,
        default="UTC",
        help_text="IANA timezone (e.g., 'America/Bogota', 'America/New_York')",
    )

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"


# Clase base abstracta para los perfiles.
# Vincula cualquier perfil con un usuario mediante una relación uno a uno.
# Al ser abstracta, no crea una tabla propia en la base de datos.
class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    class Meta:
        abstract = True


# Perfil específico para usuarios con rol 'athlete'.
# Almacena datos físicos y nivel de actividad del atleta.
class AthleteProfile(Profile):
    height = models.FloatField()
    age = models.IntegerField()

    GENDER_CHOICES = (
        ("male", "Male"),
        ("female", "Female"),
        ("other", "Other"),
    )
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)

    ACTIVITY_CHOICES = (
        ("high", "High"),
        ("medium", "Medium"),
        ("low", "Low"),
    )
    # Nota: altura, edad y género están en el perfil por separación de responsabilidades.
    activity_level = models.CharField(max_length=10, choices=ACTIVITY_CHOICES)

    def __str__(self):
        return f"{self.user.username} — {self.gender}, {self.age} años"


# Perfil específico para usuarios con rol 'coach'.
# Almacena información del gimnasio o negocio del entrenador.
class CoachProfile(Profile):
    SPECIALITY_CHOICES = (
        ("lose_weight", "Lose_weight"),
        ("gain_muscle", "Gain_muscle"),
        ("maintain", "Maintain"),
        ("endurance", "Endurance"),
        ("wellness", "Wellness"),
    )
    speciality = models.CharField(max_length=255, choices=SPECIALITY_CHOICES)
    years_experience = models.IntegerField()
    # Lista de atletas vinculados al coach (independiente de los grupos)
    athletes = models.ManyToManyField(User, related_name="managed_by_coaches", blank=True)

    def __str__(self):
        return f"{self.user.username} — {self.speciality}"


# Representa una meta de entrenamiento asociada a un atleta.
# Un atleta puede tener múltiples metas activas o inactivas.
class Goal(models.Model):
    GOAL_CHOICES = (
        ("lose_weight", "Lose_weight"),
        ("gain_muscle", "Gain_muscle"),
        ("maintain", "Maintain"),
        ("endurance", "Endurance"),
        ("wellness", "Wellness"),
    )
    goal_type = models.CharField(max_length=20, choices=GOAL_CHOICES)

    # Relación con el atleta dueño de la meta.
    athlete = models.ForeignKey(AthleteProfile, on_delete=models.CASCADE, related_name="goals")

    description = models.TextField(blank=True, default="")

    # Valor objetivo de la meta, por ejemplo: 70kg para pérdida de peso.
    target_value = models.FloatField(null=True, blank=True)

    # Valor actual para hacer seguimiento del progreso.
    current_value = models.FloatField(null=True, blank=True)

    start_date = models.DateField(auto_now_add=True)
    deadline = models.DateField(null=True, blank=True)

    # Indica si la meta sigue activa o ya fue completada/abandonada.
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.athlete.user.username} - {self.goal_type}"


# Registro histórico del peso de un atleta.
# Permite hacer seguimiento de la evolución física a lo largo del tiempo.
class WeightLog(models.Model):
    athlete = models.ForeignKey(AthleteProfile, on_delete=models.CASCADE, related_name="weight")
    weight = models.FloatField()

    # Porcentaje de grasa corporal — opcional, no siempre se registra.
    body_fat = models.FloatField(null=True, blank=True)

    # Se registra automáticamente la fecha en que se crea el log.
    date = models.DateField(default=timezone.now)

    def __str__(self):
        return f"{self.athlete.user.username} - {self.weight}kg ({self.date})"


class Reminder(models.Model):
    ACTIVITY_CHOICES = (
        ("training", "Training"),
        ("nutrition", "Nutrition"),
    )

    RECURRENCE_CHOICES = (
        ("none", "None"),  # Una sola vez
        ("daily", "Daily"),  # Cada día
        ("weekly", "Weekly"),  # Cada semana
        ("biweekly", "Biweekly"),  # Cada dos semanas
        ("monthly", "Monthly"),  # Cada mes
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reminders")
    activity_type = models.CharField(max_length=20, choices=ACTIVITY_CHOICES)
    remind_at = models.DateTimeField()
    recurrence = models.CharField(max_length=20, choices=RECURRENCE_CHOICES, default="none")
    timezone = models.CharField(
        max_length=50, default="UTC", help_text="IANA timezone for this reminder"
    )
    is_active = models.BooleanField(default=True)
    notified_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["remind_at"]

    def __str__(self):
        return f"{self.user.username} - {self.activity_type} ({self.remind_at})"

    @property
    def is_due(self):
        if not self.is_active:
            return False

        now = timezone.now()

        # Para recordatorios sin recurrencia: notificación única
        if self.recurrence == "none":
            return self.remind_at <= now and self.notified_at is None

        # Para recordatorios recurrentes: verificar si es tiempo de notificar
        # Primera vez: si remind_at ha llegado y no se ha notificado
        if self.notified_at is None:
            return self.remind_at <= now

        # Siguientes veces: calcular si debe notificarse nuevamente
        # Esto se evaluará cada vez que se haga polling

        next_due = self._calculate_next_due_time()
        return next_due <= now

    def _calculate_next_due_time(self):
        """Calcula el próximo tiempo de notificación basado en la recurrencia."""
        from dateutil.relativedelta import relativedelta

        if self.recurrence == "none":
            return self.remind_at

        if self.notified_at is None:
            return self.remind_at

        last_notified = self.notified_at

        if self.recurrence == "daily":
            return last_notified + relativedelta(days=1)
        elif self.recurrence == "weekly":
            return last_notified + relativedelta(weeks=1)
        elif self.recurrence == "biweekly":
            return last_notified + relativedelta(weeks=2)
        elif self.recurrence == "monthly":
            return last_notified + relativedelta(months=1)

        return self.remind_at


# Registro de un Follow, quien es el que lo hace (follower), y a quién lo hace (following)
class Follow(models.Model):
    follower = models.ForeignKey(User, on_delete=models.CASCADE, related_name="following")

    following = models.ForeignKey(User, on_delete=models.CASCADE, related_name="followers")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            # Evita que no hayan duplicados de followers
            models.UniqueConstraint(
                fields=["follower", "following"], name="unique_follow_relationship"
            ),
            # Evita que user se siga a si mismo
            models.CheckConstraint(
                condition=~Q(follower=F("following")), name="prevent_self_follow"
            ),
        ]

    def __str__(self):
        return f"{self.follower} follows {self.following}"


# ============= BADGES (INSIGNIAS) =============


class Badge(models.Model):
    """
    Define las insignias (badges) disponibles en el sistema.
    Cada insignia corresponde a un logro específico (alimentacion, ejercicio, completa, logros).
    """

    BADGE_TYPES = [
        ("alimentacion", "Racha de Alimentación"),
        ("ejercicio", "Racha de Ejercicio"),
        ("completa", "Racha Completa"),
        ("logros", "Contador de Logros"),
    ]

    badge_type = models.CharField(max_length=20, choices=BADGE_TYPES)
    level = models.IntegerField(help_text="Nivel/número de la insignia (1, 3, 7, etc.)")

    name = models.CharField(max_length=200, help_text="Nombre descriptivo de la insignia")
    description = models.TextField(help_text="Descripción de cómo se obtiene esta insignia")

    # Campo para almacenar el nombre del archivo SVG (sin ruta)
    svg_filename = models.CharField(
        max_length=255,
        help_text="Nombre del archivo SVG en backend/users/badges/svg/",
        unique=True,
    )

    # Condición para obtener la insignia (descriptivo)
    unlock_condition = models.TextField(
        help_text="Descripción de la condición requerida para desbloquear"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Badges"
        ordering = ["badge_type", "level"]
        unique_together = ("badge_type", "level")

    def __str__(self):
        return f"{self.get_badge_type_display()} - Nivel {self.level}"

    def get_svg_url(self):
        """Retorna la URL del SVG de la insignia"""
        return f"/media/badges/{self.svg_filename}"


class UserBadge(models.Model):
    """
    Representa una insignia desbloqueada por un usuario.
    Permite rastrear qué insignias tiene cada usuario y cuándo las obtuvo.
    """

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="badges")
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE, related_name="unlocked_by")

    unlocked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = "User Badges"
        unique_together = ("user", "badge")
        ordering = ["-unlocked_at"]

    def __str__(self):
        return (
            f"{self.user.username} - {self.badge.get_badge_type_display()} Nivel {self.badge.level}"
        )
