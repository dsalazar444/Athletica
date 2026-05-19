from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    AthleteDashboardView,
    AthleteSearchView,
    AthleteStatsView,
    BadgeDetailView,
    BadgesListView,
    CheckBadgesView,
    CoachAthleteManagementView,
    CoachDashboardView,
    ComparativeStatsView,
    CustomTokenObtainPairView,
    GoalDetailView,
    GoalLogView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    ProfileSettingsView,
    RegisterView,
    ReminderDetailView,
    ReminderDueView,
    ReminderListCreateView,
    UserBadgesView,
    WeightLogView,
    followUser,
    protected_test,
    unfollowUser,
)

urlpatterns = [
    path("api/auth/register/", RegisterView, name="register"),
    path("api/auth/login/", CustomTokenObtainPairView.as_view(), name="login"),
    path("api/auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/auth/me/", protected_test, name="me"),
    path("api/users/profile/settings/", ProfileSettingsView, name="profile_settings"),
    # Coach - Athlete management
    path("api/users/athletes/search/", AthleteSearchView, name="athlete_search"),
    path("api/users/coach/athletes/", CoachAthleteManagementView, name="coach_athletes"),
    path(
        "api/users/coach/athletes/<int:athlete_id>/",
        CoachAthleteManagementView,
        name="coach_athlete_action",
    ),
    path("api/dashboard/athlete/", AthleteDashboardView, name="athlete_dashboard"),
    path("api/dashboard/coach/", CoachDashboardView, name="coach_dashboard"),
    path("api/athlete/weight-logs/", WeightLogView, name="weight_logs"),
    path("api/athlete/goals/", GoalLogView, name="goals"),
    path("api/athlete/goals/<int:goal_id>/", GoalDetailView, name="goal_detail"),
    path("api/reminders/", ReminderListCreateView, name="reminders"),
    path("api/reminders/<int:reminder_id>/", ReminderDetailView, name="reminder_detail"),
    path("api/reminders/due/", ReminderDueView, name="reminders_due"),
    # Follow/Unfollow endpoints
    path("api/users/<int:user_id>/follow/", followUser, name="follow_user"),
    path("api/users/<int:user_id>/unfollow/", unfollowUser, name="unfollow_user"),
    path(
        "api/dashboard/athlete/comparative-stats/", ComparativeStatsView, name="comparative_stats"
    ),
    path("api/auth/password-reset/", PasswordResetRequestView, name="password_reset"),
    path(
        "api/auth/password-reset-confirm/", PasswordResetConfirmView, name="password_reset_confirm"
    ),
    # Badge endpoints
    path("api/badges/", BadgesListView, name="badges_list"),
    path("api/badges/<int:badge_id>/", BadgeDetailView, name="badge_detail"),
    path("api/me/badges/", UserBadgesView, name="user_badges"),
    path("api/me/badges/check/", CheckBadgesView, name="check_badges"),
    path("api/coach/athletes/<int:athlete_id>/stats/", AthleteStatsView, name="athlete_stats"),
]
