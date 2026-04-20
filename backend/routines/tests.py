from datetime import datetime

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from routines.models import Routine, WorkoutSession
from users.models import User


class WorkoutHistoryByDateRangeViewTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.user_daniela = User.objects.create_user(
            username="daniela",
            password="test123",  # nosec
            email="daniela@test.com",
            role="athlete",
        )
        self.client.force_authenticate(user=self.user_daniela)
        self.other_user = User.objects.create_user(
            username="otro_usuario",
            password="test123",  # nosec
            email="otro@test.com",
            role="athlete",
        )

        self.routine_daniela = Routine.objects.create(
            title="Rutina Daniela",
            description="desc",
            category="strength",
            difficulty="beginner",
            created_by=self.user_daniela,
        )
        self.routine_other = Routine.objects.create(
            title="Rutina Otro",
            description="desc",
            category="cardio",
            difficulty="intermediate",
            created_by=self.other_user,
        )

        self.routine_daniela.assigned_athletes.add(self.user_daniela)
        self.routine_other.assigned_athletes.add(self.other_user)

    def test_history_filters_by_date_range_and_orders_by_date(self):
        WorkoutSession.objects.create(
            user=self.user_daniela,
            routine=self.routine_daniela,
            date=timezone.make_aware(datetime(2026, 3, 5, 9, 0, 0)),
        )
        in_range_older = WorkoutSession.objects.create(
            user=self.user_daniela,
            routine=self.routine_daniela,
            date=timezone.make_aware(datetime(2026, 3, 10, 8, 0, 0)),
        )
        in_range_newer = WorkoutSession.objects.create(
            user=self.user_daniela,
            routine=self.routine_daniela,
            date=timezone.make_aware(datetime(2026, 3, 12, 18, 0, 0)),
        )

        response = self.client.get(
            "/api/sessions/history/",
            {"start_date": "2026-03-10", "end_date": "2026-03-12"},
        )
        payload = response.json()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(payload["count"], 2)
        self.assertEqual(len(payload["results"]), 2)
        # Se espera orden descendente (más reciente primero) según la lógica del ViewSet
        self.assertEqual(payload["results"][0]["id"], in_range_newer.pk)
        self.assertEqual(payload["results"][1]["id"], in_range_older.pk)

    def test_history_does_not_return_data_from_other_users(self):
        WorkoutSession.objects.create(
            user=self.user_daniela,
            routine=self.routine_daniela,
            date=timezone.make_aware(datetime(2026, 3, 11, 10, 0, 0)),
        )
        WorkoutSession.objects.create(
            user=self.other_user,
            routine=self.routine_other,
            date=timezone.make_aware(datetime(2026, 3, 11, 11, 0, 0)),
        )

        response = self.client.get(
            "/api/sessions/history/",
            {"start_date": "2026-03-10", "end_date": "2026-03-12"},
        )
        payload = response.json()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(payload["count"], 1)
        self.assertEqual(len(payload["results"]), 1)
        self.assertEqual(payload["results"][0]["routine_title"], "Rutina Daniela")

    def test_history_supports_pagination_params(self):
        for day in range(1, 6):
            WorkoutSession.objects.create(
                user=self.user_daniela,
                routine=self.routine_daniela,
                date=timezone.make_aware(datetime(2026, 3, day, 7, 0, 0)),
            )

        response = self.client.get(
            "/api/sessions/history/",
            {
                "start_date": "2026-03-01",
                "end_date": "2026-03-31",
                "page": 2,
                "page_size": 2,
            },
        )
        payload = response.json()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(payload["count"], 5)
        self.assertEqual(len(payload["results"]), 2)
        self.assertIsNotNone(payload["next"])
        self.assertIsNotNone(payload["previous"])

    def test_history_returns_400_when_date_params_are_missing_or_invalid(self):
        missing_response = self.client.get("/api/sessions/history/")
        invalid_response = self.client.get(
            "/api/sessions/history/",
            {"start_date": "2026-03-15", "end_date": "invalid-date"},
        )

        self.assertEqual(missing_response.status_code, 400)
        self.assertEqual(invalid_response.status_code, 400)


class ExerciseRegistrationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username="atleta",
            password="password123",
            role="athlete",
            email="athlete_reg@test.com",  # nosec
        )
        self.client.force_authenticate(user=self.user)

        from routines.models import Exercise

        self.exercise = Exercise.objects.create(
            external_id=123,
            name="Sentadilla",
        )
        self.routine = Routine.objects.create(
            title="Rutina de Pierna",
            created_by=self.user,
        )

    def test_create_session_and_record_sets(self):
        # CP1 & CP4: Crear sesión vinculada a rutina
        response_session = self.client.post(
            "/api/sessions/",
            {"routine": self.routine.id},
        )
        self.assertEqual(response_session.status_code, 201)
        session_id = response_session.data["id"]

        # CP3 & CA3: Registrar series, repeticiones y peso
        response_log = self.client.post(
            "/api/sets/",
            {
                "session": session_id,
                "exercise": self.exercise.id,
                "set_number": 1,
                "reps": 12,
                "weight": 60.5,
            },
        )
        self.assertEqual(response_log.status_code, 201)

        # CP5 & CA5: Verificar persistencia en BD
        from routines.models import SetLog

        log = SetLog.objects.get(session_id=session_id)
        self.assertEqual(log.reps, 12)
        self.assertEqual(float(log.weight), 60.5)

    def test_cannot_register_invalid_data(self):
        # Flujo alternativo: Datos inválidos (reps negativas)
        response_session = self.client.post(
            "/api/sessions/",
            {"routine": self.routine.id},
        )
        session_id = response_session.data["id"]

        response_log = self.client.post(
            "/api/sets/",
            {
                "session": session_id,
                "exercise": self.exercise.id,
                "set_number": 1,
                "reps": -5,
                "weight": 60.5,
            },
        )
        # Debería ser 400 debido a validación de PositiveIntegerField o similar
        self.assertEqual(response_log.status_code, 400)

    def test_remove_exercise_from_routine(self):
        # CP2 & CA2: Eliminar ejercicio de una rutina
        from routines.models import RoutineExercise

        RoutineExercise.objects.create(routine=self.routine, exercise=self.exercise, order=1)

        # Eliminarlo mediante la acción remove_exercise
        response = self.client.delete(
            f"/api/routines/{self.routine.id}/exercises/{self.exercise.id}/"
        )
        self.assertEqual(response.status_code, 204)

        # Verificar que ya no existe la relación
        self.assertFalse(
            RoutineExercise.objects.filter(
                routine=self.routine, exercise=self.exercise
            ).exists()
        )


class RoutineAssignmentTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.coach = User.objects.create_user(
            username="coach_test",
            password="password123",
            role="coach",
            email="coach@test.com",  # nosec
        )
        self.athlete = User.objects.create_user(
            username="athlete_test",
            password="password123",
            role="athlete",
            email="athlete@test.com",  # nosec
        )
        self.routine_1 = Routine.objects.create(
            title="Rutina A",
            created_by=self.coach,
        )
        self.routine_2 = Routine.objects.create(
            title="Rutina B",
            created_by=self.coach,
        )

    def test_coach_can_assign_routine_to_athlete(self):
        self.client.force_authenticate(user=self.coach)
        response = self.client.post(
            f"/api/routines/{self.routine_1.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(self.routine_1.assigned_athletes.filter(id=self.athlete.id).exists())

    def test_one_active_routine_replacement(self):
        self.client.force_authenticate(user=self.coach)

        # Asignar primera rutina
        self.client.post(
            f"/api/routines/{self.routine_1.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
        )
        self.assertTrue(self.routine_1.assigned_athletes.filter(id=self.athlete.id).exists())

        # Asignar segunda rutina (debe reemplazar a la primera)
        response = self.client.post(
            f"/api/routines/{self.routine_2.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
        )
        self.assertEqual(response.status_code, 200)

        # Verificar que ya no está en la 1 y sí en la 2
        self.assertFalse(self.routine_1.assigned_athletes.filter(id=self.athlete.id).exists())
        self.assertTrue(self.routine_2.assigned_athletes.filter(id=self.athlete.id).exists())

    def test_athlete_cannot_assign_routine(self):
        self.client.force_authenticate(user=self.athlete)
        response = self.client.post(
            f"/api/routines/{self.routine_1.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
        )
        # Solo coaches pueden asignar
        self.assertEqual(response.status_code, 403)

    def test_get_active_routine_details(self):
        self.client.force_authenticate(user=self.coach)
        self.client.post(
            f"/api/routines/{self.routine_1.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
        )

        # Consultar la rutina activa del atleta
        response = self.client.get(f"/api/routines/athlete/{self.athlete.id}/active/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["title"], "Rutina A")

    def test_coach_list_empty_routines(self):
        # Escenario: Coach sin rutinas
        new_coach = User.objects.create_user(
            username="coach_empty",
            password="password123",
            role="coach",
            email="empty@test.com",  # nosec
        )
        self.client.force_authenticate(user=new_coach)

        response = self.client.get("/api/routines/")
        self.assertEqual(response.status_code, 200)
        # Debe retornar lista vacía
        self.assertEqual(len(response.data), 0)

    def test_assign_from_non_existent_routine(self):
        self.client.force_authenticate(user=self.coach)
        # ID que no existe
        response = self.client.post(
            "/api/routines/9999/assign/",
            {"athlete_ids": [self.athlete.id]},
        )
        self.assertEqual(response.status_code, 404)

