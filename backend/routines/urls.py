from django.urls import path

from .views import (
    ExerciseHistoryView,
    ExerciseListCreateView,
    LastExerciseLogView,
    RoutineDetailView,
    RoutineExerciseDeleteView,
    RoutineListCreateView,
    SetLogCreateView,
    SetLogDetailView,
    WorkoutHistoryByDateRangeView,
    WorkoutSessionListCreateView,
)

urlpatterns = [
    # path para crear-verificar si exite un ejercicio.
    path("api/exercises/", ExerciseListCreateView.as_view(), name="exercise-list-create"),
    # path para crear routine
    path("api/routines/", RoutineListCreateView.as_view(), name="routine-list-create"),
    # path to list routine details
    path("api/routines/<int:routine_id>/", RoutineDetailView.as_view(), name="routine-detail"),
    path(
        "api/routines/<int:routine_id>/exercises/<int:exercise_id>/",
        RoutineExerciseDeleteView.as_view(),
        name="routine-exercise-delete",
    ),
    # Tracking endpoints
    path("api/sessions/", WorkoutSessionListCreateView.as_view(), name="session-list-create"),
    path(
        "api/sessions/history/",
        WorkoutHistoryByDateRangeView.as_view(),
        name="session-history-by-date-range",
    ),
    path("api/sets/", SetLogCreateView.as_view(), name="set-create"),
    path("api/sets/<int:pk>/", SetLogDetailView.as_view(), name="set-detail"),
    path(
        "api/exercises/<int:exercise_id>/last/",
        LastExerciseLogView.as_view(),
        name="last-exercise-log",
    ),
    path(
        "api/exercises/<int:exercise_id>/history/",
        ExerciseHistoryView.as_view(),
        name="exercise-history",
    ),
]
