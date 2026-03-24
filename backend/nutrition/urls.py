from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MealRecordViewSet

router = DefaultRouter()
router.register(r'meals', MealRecordViewSet, basename='meal')

urlpatterns = [
    path('nutrition/', include(router.urls)),
]