from django.test import TestCase
from rest_framework.test import APIClient

from routines.models import Exercise, Routine, RoutineExercise
from users.models import User


class CreateRoutineTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.user_daniela = User.objects.create_user(
            username="daniela",
            password="test123",  # nosec
            email="daniela@test.com",
            role="athlete",
        )
        self.client.force_authenticate(user=self.user_daniela)

        self.exercise = Exercise.objects.create(
            external_id=123,
            name="Sentadilla",
            description="Ejercicio base de piernas",
            muscle="piernas",
        )

    def test_can_create_routine(self):
        """Happy path -> crea una rutina con un ejercicio válido."""
        response = self.client.post(
            "/api/routines/",
            {
                "title": "Rutina Pierna",
                "description": "Rutina para tren inferior",
                "category": "strength",
                "difficulty": "beginner",
                "exercises": [
                    {
                        "external_id": self.exercise.external_id,
                        "order": 1,
                    }
                ],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["title"], "Rutina Pierna")

        routine = Routine.objects.get(title="Rutina Pierna", created_by=self.user_daniela)
        self.assertEqual(routine.created_by, self.user_daniela)
        self.assertTrue(routine.assigned_athletes.filter(id=self.user_daniela.id).exists())
        self.assertTrue(
            RoutineExercise.objects.filter(
                routine=routine,
                exercise=self.exercise,
                order=1,
            ).exists()
        )

    def test_cannot_create_routine_with_duplicate_title(self):
        """Alternative path -> el mismo usuario no puede repetir el título."""
        Routine.objects.create(
            title="Rutina Pierna",
            description="Rutina ya existente",
            category="strength",
            difficulty="beginner",
            created_by=self.user_daniela,
        )

        response = self.client.post(
            "/api/routines/",
            {
                "title": "Rutina Pierna",
                "description": "Rutina duplicada",
                "category": "strength",
                "difficulty": "beginner",
                "exercises": [
                    {
                        "external_id": self.exercise.external_id,
                        "order": 1,
                    }
                ],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("Ya tienes una rutina con el titulo", str(response.data))
