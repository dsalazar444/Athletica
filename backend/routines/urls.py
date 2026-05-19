from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    ExerciseRecommendationView,
    ExerciseViewSet,
    GroupDashboardView,
    RoutineViewSet,
    SetLogViewSet,
    TrainingGroupViewSet,
    WorkoutSessionViewSet,
    comment_react,
    delete_comment,
)

router = DefaultRouter()
router.register(r"api/routines", RoutineViewSet, basename="routine")
router.register(r"api/sessions", WorkoutSessionViewSet, basename="session")
router.register(r"api/sets", SetLogViewSet, basename="set")
router.register(r"api/exercises", ExerciseViewSet, basename="exercise")
router.register(r"api/groups", TrainingGroupViewSet, basename="group")


urlpatterns = [
    path(
        "api/routines/recommendations/",
        ExerciseRecommendationView.as_view(),
        name="exercise-recommendations",
    ),
    path("", include(router.urls)),
    path(
        "api/athletes/<int:athlete_id>/routine/",
        RoutineViewSet.as_view({"get": "active_routine"}),
        name="athlete-active-routine",
    ),
    path(
        "api/groups/<int:group_id>/dashboard/",
        GroupDashboardView,
        name="group_dashboard",
    ),
    path("api/comments/<int:comment_id>/", delete_comment, name="delete-comment"),
    path("api/comments/<int:comment_id>/react/", comment_react, name="comment-react"),
]
