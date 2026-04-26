from django.contrib import admin
from .models import AthleteProfile, CoachProfile, Goal, User, WeightLog


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "email", "role", "is_active", "date_joined")
    list_filter = ("role", "is_active")
    search_fields = ("username", "email")


@admin.register(AthleteProfile)
class AthleteProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "gender", "age", "height", "activity_level")
    list_filter = ("gender", "activity_level")
    search_fields = ("user__username", "user__email")


@admin.register(CoachProfile)
class CoachProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "speciality", "years_experience")
    search_fields = ("user__username", "speciality")
    filter_horizontal = ("athletes",)

@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ("athlete", "goal_type", "target_value", "current_value", "start_date", "deadline", "is_active")
    list_filter = ("goal_type", "is_active")
    search_fields = ("athlete__user__username",)


@admin.register(WeightLog)
class WeightLogAdmin(admin.ModelAdmin):
    list_display = ("athlete", "weight", "body_fat", "date")
    list_filter = ("date",)
    search_fields = ("athlete__user__username",)
