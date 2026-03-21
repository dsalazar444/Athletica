from django.db import models
from django.contrib.auth.models import AbstractUser

#Solo define el usuario y el rol
class User(AbstractUser):
    ROLE_CHOICES = (
            ('athlete', 'Athlete'),
            ('coach', 'Coach'),
        )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    
    email = models.EmailField(unique=True)
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
#Crea el usuario
class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    class Meta:
        abstract = True
            
#Perfil de atleta            
class AthleteProfile(Profile):
    height = models.FloatField()
    age = models.IntegerField()
    GENDER_CHOICES = (
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
    )
    gender = models.CharField(max_length=10,choices=GENDER_CHOICES)
    ACTIVITY_CHOICES=(
            ('high', 'High'),
            ('medium', 'Medium'),
            ('low', 'Low'),
    )
    activity_level = models.CharField(max_length=10, choices=ACTIVITY_CHOICES)  
    
    def __str__(self):
        return f"{self.user.username} — {self.gender}, {self.age} años"
    
#Perfil del coach   
class CoachProfile(Profile):
    gym_name = models.CharField(max_length=255)
    business_address = models.CharField(max_length=255)
    
    def __str__(self):
        return f"{self.user.username} — {self.gym_name}"

#Metas de los usuarios
class Goal(models.Model):
    GOAL_CHOICES = (
        ('lose_weight', 'Lose_weight'),
        ('gain_muscle', 'Gain_muscle'),
        ('maintain', 'Maintain'),
        ('endurance', 'Endurance'),
        ('wellness', 'Wellness'),
    )
    goal_type = models.CharField(max_length=20, choices=GOAL_CHOICES)
    athlete = models.ForeignKey(
        AthleteProfile,
        on_delete=models.CASCADE,
        related_name='goals'
    )
    description = models.TextField(blank=True)

    target_value = models.FloatField(null=True, blank=True)  # ej: 70kg
    current_value = models.FloatField(null=True, blank=True)

    start_date = models.DateField(auto_now_add=True)
    deadline = models.DateField(null=True, blank=True)

    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.athlete.user.username} - {self.goal_type}"
    
#Para metricas de peso
class WeightLog(models.Model):
    athlete = models.ForeignKey(AthleteProfile,on_delete=models.CASCADE,related_name="weight")
    weight = models.FloatField()
    body_fat = models.FloatField(null=True, blank=True)
    date = models.DateField(auto_now_add=True)