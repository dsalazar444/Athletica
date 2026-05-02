from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    CustomTokenObtainPairView,
    athlete_dashboard_view,
    athlete_search_view,
    coach_athlete_management_view,
    coach_dashboard_view,
    profile_settings_view,
    protected_test,
    register_view,
    weight_log_view,
)

urlpatterns = [
    path("api/auth/register/", register_view, name="register"),
    path("api/auth/login/", CustomTokenObtainPairView.as_view(), name="login"),
    path("api/auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/auth/me/", protected_test, name="me"),
    path("api/users/profile/settings/", profile_settings_view, name="profile_settings"),
    # Coach - Athlete management
    path("api/users/athletes/search/", athlete_search_view, name="athlete_search"),
    path("api/users/coach/athletes/", coach_athlete_management_view, name="coach_athletes"),
    path(
        "api/users/coach/athletes/<int:athlete_id>/",
        coach_athlete_management_view,
        name="coach_athlete_action",
    ),
    path("api/dashboard/athlete/", athlete_dashboard_view, name="athlete_dashboard"),
    path("api/dashboard/coach/", coach_dashboard_view, name="coach_dashboard"),
    path("api/athlete/weight-logs/", weight_log_view, name="weight_logs"),
]
