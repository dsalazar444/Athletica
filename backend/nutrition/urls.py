from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import MealRecordViewSet, NutritionPlanViewSet

router = DefaultRouter()
router.register(r"meals", MealRecordViewSet, basename="meal")
router.register(r"plans", NutritionPlanViewSet, basename="nutritionplan")

urlpatterns = [
    path("nutrition/", include(router.urls)),
]
