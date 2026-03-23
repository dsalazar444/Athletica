from django.contrib import admin
from .models import Exercise, Routine, RoutineExercise
from users.models import User

admin.site.register(Exercise)
admin.site.register(Routine)
admin.site.register(RoutineExercise)
admin.site.register(User)

