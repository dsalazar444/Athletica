from django.contrib import admin

from .models import Exercise, Routine, RoutineExercise

admin.site.register(Exercise)
admin.site.register(Routine)
admin.site.register(RoutineExercise)
