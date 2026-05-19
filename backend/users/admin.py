from django.contrib import admin

from .models import (
    AthleteProfile,
    Badge,
    CoachProfile,
    Follow,
    Goal,
    Reminder,
    User,
    UserBadge,
    WeightLog,
)

admin.site.register(Follow)


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
    list_display = (
        "athlete",
        "goal_type",
        "target_value",
        "current_value",
        "start_date",
        "deadline",
        "is_active",
    )
    list_filter = ("goal_type", "is_active")
    search_fields = ("athlete__user__username",)


@admin.register(WeightLog)
class WeightLogAdmin(admin.ModelAdmin):
    list_display = ("athlete", "weight", "body_fat", "date")
    list_filter = ("date",)
    search_fields = ("athlete__user__username",)


@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ("badge_type", "level", "name", "svg_filename")
    list_filter = ("badge_type", "level")
    search_fields = ("name", "description")
    readonly_fields = ("created_at", "updated_at")
    fieldsets = (
        ("Información", {"fields": ("badge_type", "level", "name", "description")}),
        ("Media", {"fields": ("svg_filename",)}),
        ("Condiciones", {"fields": ("unlock_condition",)}),
        ("Timestamps", {"fields": ("created_at", "updated_at"), "classes": ("collapse",)}),
    )


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ("user", "badge", "unlocked_at")
    list_filter = ("badge__badge_type", "unlocked_at")
    search_fields = ("user__username", "badge__name")
    readonly_fields = ("unlocked_at",)


@admin.register(Reminder)
class ReminderAdmin(admin.ModelAdmin):
    list_display = ("user", "activity_type", "remind_at", "is_active", "notified_at")
    list_filter = ("activity_type", "is_active")
    search_fields = ("user__username", "user__email")
