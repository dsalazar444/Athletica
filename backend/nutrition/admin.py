from django.contrib import admin

from .models import MealRecord


@admin.register(MealRecord)
class MealRecordAdmin(admin.ModelAdmin):
    list_display = ["athlete", "meal_type", "food_name", "calories", "date"]
    list_filter = ["meal_type", "date"]
    search_fields = ["athlete__user__username", "food_name"]
    ordering = ["-date"]
