from django.contrib import admin

from users.models import User

from .models import Exercise, Routine, RoutineExercise

admin.site.register(Exercise)
admin.site.register(Routine)
admin.site.register(RoutineExercise)
admin.site.register(User)
