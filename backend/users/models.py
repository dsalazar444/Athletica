from django.db import models
from django.contrib.auth.models import AbstractUser

"""
ATTRIBUTES:
- username, email, password, etc. (inherited from AbstractUser)
- role -> CharField -> indicates if the user is an athlete or a coach
"""
class User(AbstractUser):
    ROLE_CHOICES = (
        ('athlete', 'Athlete'),
        ('coach', 'Coach'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)