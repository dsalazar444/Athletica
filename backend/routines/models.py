from django.db import models
from users.models import User

"""
ATRIBUTES:
- name -> string -> routine name
- description -> string -> routine description
- created_by -> ForeignKey -> indicates who created the routine (an athlete or a coach)
- assigned_athletes -> ManyToMany -> indicates to whom the routine was assigned (to themselves, in the case of an athlete, or to other athletes, in the case of a coach)
"""

class Routine(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(null=True)

    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_routines'
    )

    assigned_athletes = models.ManyToManyField(
        User,
        related_name='routines',
        blank=True
    )
    