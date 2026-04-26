from django.contrib.auth.models import AbstractUser
from django.db import models


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
    speciality = models.CharField(max_length=255,choices=SPECIALITY_CHOICES)
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
    date = models.DateField(auto_now_add=True)

    def __str__(self):
        return f"{self.athlete.user.username} - {self.weight}kg ({self.date})"
