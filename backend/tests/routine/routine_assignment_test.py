from django.test import TestCase
from rest_framework.test import APIClient

from routines.models import Routine
from users.models import User


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
        # Asegurar persistencia del rol para evitar fallos en filtros de la API
        self.athlete.role = "athlete"
        self.athlete.save()
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
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(self.routine_1.assigned_athletes.filter(id=self.athlete.id).exists())

    def test_one_active_routine_replacement(self):
        self.client.force_authenticate(user=self.coach)

        # Asignar primera rutina
        assign_response1 = self.client.post(
            f"/api/routines/{self.routine_1.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
            format="json",
        )
        self.assertEqual(assign_response1.status_code, 200)

        self.routine_1.refresh_from_db()
        # Verificar directamente en la relación ManyToMany
        self.assertTrue(
            self.routine_1.assigned_athletes.filter(id=self.athlete.id).exists()
        )

        # Asignar segunda rutina (debe reemplazar a la primera)
        assign_response2 = self.client.post(
            f"/api/routines/{self.routine_2.id}/assign/",
            {"athlete_ids": [self.athlete.id]},
            format="json",
        )
        self.assertEqual(assign_response2.status_code, 200)

        # Verificar que ya no está en la 1 y sí en la 2
        self.routine_1.refresh_from_db()
        self.routine_2.refresh_from_db()
        self.assertFalse(
            self.routine_1.assigned_athletes.filter(id=self.athlete.id).exists()
        )
        self.assertTrue(
            self.routine_2.assigned_athletes.filter(id=self.athlete.id).exists()
        )

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
            format="json",
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
        """Manejo de error 404 al intentar asignar una rutina inexistente."""
        self.client.force_authenticate(user=self.coach)
        # ID que no existe
        response = self.client.post(
            "/api/routines/9999/assign/",
            {"athlete_ids": [self.athlete.id]},
            format="json",
        )
        self.assertEqual(response.status_code, 404)

    def test_assignment_fails_when_no_routines_available(self):
        """Garantizar que un entrenador sin rutinas no pueda realizar asignaciones (estado vacío)."""
        new_coach = User.objects.create_user(
            username="coach_sin_nada",
            password="password123",
            role="coach",
            email="nada@test.com",
        )
        self.client.force_authenticate(user=new_coach)

        # Intenta asignar un ID cualquiera (ya que no tiene ninguno propio)
        response = self.client.post(
            "/api/routines/1/assign/", {"athlete_ids": [self.athlete.id]}, format="json"
        )

        # El backend debe manejar el estado vacío retornando 404 o 403, no permitiendo la operación
        self.assertIn(response.status_code, [403, 404])

    def test_e2e_assignment_flow(self):
        """E2E: Flujo completo desde Login hasta verificación de asignación."""
        # Pre-requisito: El ejercicio debe existir para que el serializer de rutina no falle
        from routines.models import Exercise

        exercise = Exercise.objects.create(
            external_id=999, name="Ejercicio E2E", muscle="Pecho"
        )

        # 1. Login del Entrenador (Ruta corregida)
        login_response = self.client.post(
            "/api/auth/login/",
            {"username": "coach_test", "password": "password123"},
        )
        self.assertEqual(login_response.status_code, 200)
        token = login_response.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        # 2. Crear una nueva rutina (usando el endpoint)
        # IMPORTANTE: Incluir 'exercises' para que el RoutineCreateSerializer sea válido
        create_response = self.client.post(
            "/api/routines/",
            {
                "title": "Rutina E2E",
                "description": "Creada en flujo completo",
                "category": "strength",
                "difficulty": "intermediate",
                "exercises": [{"external_id": exercise.external_id, "order": 1}],
            },
            format="json",
        )
        self.assertEqual(create_response.status_code, 201)
        routine_id = create_response.data["id"]

        # 3. Asignar al atleta
        assign_response = self.client.post(
            f"/api/routines/{routine_id}/assign/",
            {"athlete_ids": [self.athlete.id]},
            format="json",
        )
        self.assertEqual(assign_response.status_code, 200)

        # 4. Verificar como Atleta
        self.client.force_authenticate(user=self.athlete)
        active_response = self.client.get(
            f"/api/routines/athlete/{self.athlete.id}/active/"
        )
        self.assertEqual(active_response.status_code, 200)
        self.assertEqual(active_response.data["title"], "Rutina E2E")
