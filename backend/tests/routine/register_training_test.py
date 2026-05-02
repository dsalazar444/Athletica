from django.test import TestCase
from rest_framework.test import APIClient

from routines.models import Exercise, Routine, RoutineExercise
from users.models import User


class RegisterTrainingTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.user_daniela = User.objects.create_user(
            username="daniela",
            password="test123",  # nosec
            email="daniela@test.com",
            role="athlete",
        )
        self.client.force_authenticate(user=self.user_daniela)

        self.routine_daniela = Routine.objects.create(
            title="Rutina Daniela",
            description="desc",
            category="strength",
            difficulty="beginner",
            created_by=self.user_daniela,
        )

        self.routine_daniela.assigned_athletes.add(self.user_daniela)

        self.exercise = Exercise.objects.create(
            external_id=123,
            name="Sentadilla",
            description="Ejercicio base de piernas",
            muscle="piernas",
        )
        RoutineExercise.objects.create(
            routine=self.routine_daniela,
            exercise=self.exercise,
            order=1,
        )

    def test_can_register_session_and_set(self):
        """Happy path -> pesos y reps positivos"""
        response_session = self.client.post(
            "/api/sessions/",
            {"routine": self.routine_daniela.id},
        )
        self.assertEqual(response_session.status_code, 201)
        session_id = response_session.data["id"]

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

    def test_cannot_register_invalid_data(self):
        """Alternative path -> pesos y reps negativos"""
        response_session = self.client.post(
            "/api/sessions/",
            {"routine": self.routine_daniela.id},
        )
        self.assertEqual(response_session.status_code, 201)
        session_id = response_session.data["id"]

        invalid_payloads = [
            {"reps": -5, "weight": 60.5},
            {"reps": 5, "weight": -60.5},
        ]

        for payload in invalid_payloads:
            with self.subTest(payload=payload):
                response_log = self.client.post(
                    "/api/sets/",
                    {
                        "session": session_id,
                        "exercise": self.exercise.id,
                        "set_number": 1,
                        **payload,
                    },
                )
                self.assertEqual(response_log.status_code, 400)
