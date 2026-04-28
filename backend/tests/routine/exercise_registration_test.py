from django.test import TestCase
from rest_framework.test import APIClient

from routines.models import Exercise, Routine, RoutineExercise, SetLog
from users.models import User


class ExerciseRegistrationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username="atleta_registro",
            password="password123",
            role="athlete",
            email="athlete_reg_full@test.com",
        )
        self.client.force_authenticate(user=self.user)

        self.exercise = Exercise.objects.create(
            external_id=789,
            name="Sentadilla Profunda",
        )
        self.routine = Routine.objects.create(
            title="Rutina de Piernas Completa",
            created_by=self.user,
        )

    def test_add_exercise_to_routine(self):
        """CP1, CA1, CA4: Agregar ejercicio a una rutina (Integración)"""
        # Se valida que el ejercicio quede asociado a la rutina
        routine_ex = RoutineExercise.objects.create(
            routine=self.routine, exercise=self.exercise, order=1
        )

        self.assertEqual(routine_ex.routine.title, "Rutina de Piernas Completa")
        self.assertEqual(routine_ex.exercise.name, "Sentadilla Profunda")
        self.assertTrue(
            RoutineExercise.objects.filter(routine=self.routine, exercise=self.exercise).exists()
        )

    def test_create_session_and_record_sets_full_flow(self):
        """CP1, CP3, CP5, CA3, CA5: Flujo completo, registro de series y persistencia (E2E/Integración)"""
        # 1. Iniciar entrenamiento (crear sesión)
        response_session = self.client.post(
            "/api/sessions/",
            {"routine": self.routine.id},
        )
        self.assertEqual(response_session.status_code, 201)
        session_id = response_session.data["id"]

        # 2. Registrar series, repeticiones y peso
        response_log = self.client.post(
            "/api/sets/",
            {
                "session": session_id,
                "exercise": self.exercise.id,
                "set_number": 1,
                "reps": 12,
                "weight": 80.0,
            },
        )
        self.assertEqual(response_log.status_code, 201)

        # 3. Verificar persistencia en base de datos
        log = SetLog.objects.get(session_id=session_id)
        self.assertEqual(log.reps, 12)
        self.assertEqual(float(log.weight), 80.0)
        self.assertEqual(log.exercise.name, "Sentadilla Profunda")

    def test_cannot_register_invalid_data(self):
        """CA3: Validación de datos inválidos (Integración)"""
        response_session = self.client.post(
            "/api/sessions/",
            {"routine": self.routine.id},
        )
        session_id = response_session.data["id"]

        # Intentar registrar reps negativas
        response_log = self.client.post(
            "/api/sets/",
            {
                "session": session_id,
                "exercise": self.exercise.id,
                "set_number": 1,
                "reps": -10,
                "weight": 80.0,
            },
        )
        self.assertEqual(response_log.status_code, 400)

    def test_remove_exercise_from_routine(self):
        """CP2, CA2: Eliminar ejercicio de una rutina (Integración)"""
        RoutineExercise.objects.create(routine=self.routine, exercise=self.exercise, order=1)

        # Eliminar mediante endpoint
        response = self.client.delete(
            f"/api/routines/{self.routine.id}/exercises/{self.exercise.id}/"
        )
        self.assertEqual(response.status_code, 204)

        # Verificar desasociación en BD
        self.assertFalse(
            RoutineExercise.objects.filter(routine=self.routine, exercise=self.exercise).exists()
        )
