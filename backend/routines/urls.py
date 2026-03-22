from django.urls import path

from .views import ExerciseListCreateView, RoutineListCreateView, RoutineDetailView

urlpatterns = [
    # path para crear-verificar si exite un ejercicio.
    path('api/exercises/', ExerciseListCreateView.as_view(), name='exercise-list-create'),
    # path para crear routine
    path('api/routines/', RoutineListCreateView.as_view(), name='routine-list-create'),
    # path to list routine details
    path('api/routines/<int:routine_id>/', RoutineDetailView.as_view(), name='routine-detail'),

]