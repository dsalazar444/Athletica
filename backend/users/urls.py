from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    AthleteSearchView,
    CoachAthleteManagementView,
    CustomTokenObtainPairView,
    RegisterView,
    protected_test,
)

urlpatterns = [
    path("api/auth/register/", RegisterView, name="register"),
    path("api/auth/login/", CustomTokenObtainPairView.as_view(), name="login"),
    path("api/auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/auth/me/", protected_test, name="me"),
    # Coach - Athlete management
    path("api/users/athletes/search/", AthleteSearchView, name="athlete_search"),
    path("api/users/coach/athletes/", CoachAthleteManagementView, name="coach_athletes"),
    path(
        "api/users/coach/athletes/<int:athlete_id>/",
        CoachAthleteManagementView,
        name="coach_athlete_action",
    ),
]
