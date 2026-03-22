from django.db import models
from users.models import User

"""
ATRIBUTES:Exercise
- external_id -> id assigned to the exercise by wger API
- name -> string -> routine name
- descripcion -> string -> routine description
- muscles -> string -> main muscle that is work by the exercise
- image_url -> string -> url to the exercise image 
"""
class Exercise(models.Model):
    external_id=models.IntegerField(default=-1,unique=True)
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=200)
    muscle = models.CharField(max_length=50)
    image_url = models.CharField(max_length=200, null=True)

    def __str__(self):
        return self.name


"""
ATRIBUTES:Routine
- title -> string -> routine title
- description -> string -> routine description
- category -> string -> routine category (cardio, strength, hybrid, flexibility)
- difficulty -> string -> routine difficulty (beginner, intermediate, avanced)
- created_by -> ForeignKey -> indicates who created the routine (an athlete or a coach)
- assigned_athletes -> ManyToMany -> indicates to whom the routine was assigned (to themselves, in the case of an athlete, or to other athletes, in the case of a coach)
- exercises -> Exercise -> Exercises objects that are related to the routine
"""
class Routine(models.Model):
    class Category(models.TextChoices):
        HYBRID = 'hybrid', 'Híbrido'
        STRENGTH = 'strength', 'Fuerza'
        CARDIO = 'cardio', 'Cardio'
        FLEXIBILITY = 'flexibility', 'Flexibilidad'

    class Difficulty(models.TextChoices):
        BEGINNER = 'beginner', 'Principiante'
        INTERMEDIATE = 'intermediate', 'Intermedio'
        ADVANCED = 'advanced', 'Avanzado'

    title = models.CharField(max_length=150)
    description = models.TextField(blank=True, null=True)
    category = models.TextField()
    difficulty = models.TextField()

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

    exercises = models.ManyToManyField(
        Exercise,
        through='RoutineExercise',  # usa nuestra tabla personalizada, permitiendonos el ManyToMany
        related_name='routines',
    )

"""
ATRIBUTES:RoutineExercise
- routine -> ForeingKey -> routine asociated to an exercise
- exercise -> ForeingKey -> exercise asociated to a routine
- order -> int -> Exercise number in the associated routine
"""
class RoutineExercise(models.Model):
    """Tabla intermedia que relaciona una rutina con sus ejercicios y su orden."""
    routine = models.ForeignKey(
        Routine,
        on_delete=models.CASCADE,
        related_name='routine_exercises',
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='routine_exercises',
    )
    order = models.PositiveIntegerField()

    class Meta:
        ordering = ['order']
        unique_together = ('routine', 'order')  # no puede haber dos ejercicios en la misma posición

    def __str__(self):
        return f'{self.routine.title} - {self.exercise.name} (#{self.order})'
