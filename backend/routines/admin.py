from django.contrib import admin

from .models import Exercise, Routine, RoutineExercise, TrainingGroup

admin.site.register(Exercise)
admin.site.register(Routine)
admin.site.register(RoutineExercise)


@admin.register(TrainingGroup)
class TrainingGroupAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "coach", "member_count", "created_at")
    list_filter = ("coach", "created_at")
    search_fields = ("name", "coach__username")
    filter_horizontal = ("members",)
    ordering = ("-created_at",)

    def member_count(self, obj):
        return obj.members.count()

    member_count.short_description = "Atletas"
