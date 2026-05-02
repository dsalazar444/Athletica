import datetime

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from users.models import AthleteProfile, User

from .models import MealRecord, NutritionPlan


class MealRecordTestCase(TestCase):
    """
    Casos de prueba para el issue #12 — Registro de Alimentación.
    Cubre CP1, CP2, CP3 y CP4.
    """

    def setUp(self):
        self.client = APIClient()

        # Crear usuario y perfil atleta base para las pruebas
        self.user = User.objects.create_user(
            username="testathlete",
            password="testpass123",
            email="athlete@test.com",
            role="athlete",  # nosec
        )
        self.client.force_authenticate(user=self.user)
        self.athlete = AthleteProfile.objects.create(
            user=self.user, height=175.0, age=25, gender="male", activity_level="medium"
        )

        self.other_user = User.objects.create_user(
            username="otherathlete",
            password="testpass456",
            email="other@test.com",
            role="athlete",  # nosec
        )
        self.other_athlete = AthleteProfile.objects.create(
            user=self.other_user,
            height=170.0,
            age=28,
            gender="female",
            activity_level="high",
        )

        self.meal_url = "/api/nutrition/meals/"
        self.today = datetime.date.today().isoformat()

    # ---------------------------------------------------------------
    # CP1 — Registrar comida por fecha (CA1)
    # ---------------------------------------------------------------
    def test_CP1_register_meal_with_date(self):
        """El sistema guarda el registro asociado a la fecha indicada."""
        payload = {
            "athlete": self.athlete.id,
            "meal_type": "breakfast",
            "food_name": "Avena con frutas",
            "portion_grams": 200,
            "calories": 350,
            "date": self.today,
        }
        response = self.client.post(self.meal_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["date"], self.today)

    # ---------------------------------------------------------------
    # CP2 — Registrar tipo de comida, porción y calorías (CA2)
    # ---------------------------------------------------------------
    def test_CP2_register_meal_type_portion_calories(self):
        """El sistema guarda correctamente la información nutricional."""
        payload = {
            "athlete": self.athlete.id,
            "meal_type": "lunch",
            "food_name": "Arroz con pollo",
            "portion_grams": 350,
            "calories": 580,
            "protein_g": 40,
            "carbs_g": 60,
            "fat_g": 15,
            "date": self.today,
        }
        response = self.client.post(self.meal_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["meal_type"], "lunch")
        self.assertEqual(response.data["portion_grams"], 350.0)
        self.assertEqual(response.data["calories"], 580.0)

    # ---------------------------------------------------------------
    # CP3 — Guardado correcto del registro (CA3)
    # ---------------------------------------------------------------
    def test_CP3_record_saved_in_database(self):
        """El registro se guarda correctamente en la base de datos."""
        payload = {
            "athlete": self.athlete.id,
            "meal_type": "dinner",
            "food_name": "Ensalada César",
            "portion_grams": 250,
            "calories": 300,
            "date": self.today,
        }
        self.client.post(self.meal_url, payload, format="json")
        self.assertEqual(MealRecord.objects.count(), 1)
        record = MealRecord.objects.first()
        self.assertEqual(record.food_name, "Ensalada César")
        self.assertEqual(record.athlete, self.athlete)

    # ---------------------------------------------------------------
    # CP4 — Visualizar registros de alimentación (CA4)
    # ---------------------------------------------------------------
    def test_CP4_list_meal_records(self):
        """El sistema muestra los registros de alimentación previamente guardados."""
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="breakfast",
            food_name="Huevos revueltos",
            portion_grams=150,
            calories=220,
            date=self.today,
        )
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="snack",
            food_name="Manzana",
            portion_grams=180,
            calories=95,
            date=self.today,
        )
        response = self.client.get(self.meal_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)

    # ---------------------------------------------------------------
    # Extra — Filtro por fecha
    # ---------------------------------------------------------------
    def test_filter_by_date(self):
        """El endpoint by_date retorna solo los registros de la fecha indicada."""
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="breakfast",
            food_name="Granola",
            portion_grams=100,
            calories=400,
            date="2026-01-01",
        )
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="lunch",
            food_name="Pasta",
            portion_grams=300,
            calories=500,
            date=self.today,
        )
        response = self.client.get(f"{self.meal_url}by_date/?date=2026-01-01")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["food_name"], "Granola")

    def test_list_only_returns_authenticated_athlete_data(self):
        """Un atleta solo visualiza sus propios registros de alimentación."""
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="breakfast",
            food_name="Yogur",
            portion_grams=120,
            calories=95,
            date=self.today,
        )
        MealRecord.objects.create(
            athlete=self.other_athlete,
            meal_type="lunch",
            food_name="Pasta ajena",
            portion_grams=250,
            calories=430,
            date=self.today,
        )

        response = self.client.get(self.meal_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["food_name"], "Yogur")

    def test_filter_by_date_range_returns_only_records_in_range(self):
        """El endpoint acepta start_date/end_date para consultar rangos."""
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="breakfast",
            food_name="Avena",
            portion_grams=100,
            calories=250,
            date="2026-03-01",
        )
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="lunch",
            food_name="Pollo",
            portion_grams=180,
            calories=320,
            date="2026-03-10",
        )
        MealRecord.objects.create(
            athlete=self.athlete,
            meal_type="dinner",
            food_name="Sopa",
            portion_grams=200,
            calories=150,
            date="2026-03-20",
        )

        response = self.client.get(
            self.meal_url,
            {"start_date": "2026-03-05", "end_date": "2026-03-15"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["food_name"], "Pollo")


class NutritionPlanTestCase(TestCase):
    def setUp(self):
        from users.models import CoachProfile

        self.client = APIClient()

        self.coach_user = User.objects.create_user(
            username="testcoach",
            password="testpass123",
            email="coach@test.com",
            role="coach",
        )
        self.coach = CoachProfile.objects.create(user=self.coach_user)

        self.athlete_user = User.objects.create_user(
            username="testathlete2",
            password="testpass123",
            email="athlete2@test.com",
            role="athlete",
        )
        self.athlete = AthleteProfile.objects.create(
            user=self.athlete_user, height=180.0, age=20, gender="male", activity_level="medium"
        )
        self.plan_url = "/api/nutrition/plans/"

    def test_coach_can_create_plan(self):
        self.client.force_authenticate(user=self.coach_user)
        payload = {"title": "Dieta Volumen", "description": "1000 kcal"}
        response = self.client.post(self.plan_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(NutritionPlan.objects.count(), 1)

    def test_athlete_cannot_create_plan(self):
        self.client.force_authenticate(user=self.athlete_user)
        payload = {"title": "Dieta Volumen", "description": "1000 kcal"}
        response = self.client.post(self.plan_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_assign_plan_to_athlete(self):
        self.client.force_authenticate(user=self.coach_user)
        plan = NutritionPlan.objects.create(coach=self.coach_user, title="Plan", description="Desc")
        url = f"{self.plan_url}{plan.id}/assign/"
        payload = {"athlete_ids": [self.athlete_user.id]}
        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        plan.refresh_from_db()
        self.assertIn(self.athlete_user, plan.assigned_athletes.all())

    def test_assign_plan_forbidden_for_other_coach(self):
        other_coach = User.objects.create_user(username="coach2", password="123", role="coach")
        self.client.force_authenticate(user=other_coach)
        plan = NutritionPlan.objects.create(coach=self.coach_user, title="Plan", description="Desc")
        url = f"{self.plan_url}{plan.id}/assign/"
        response = self.client.post(url, {"athlete_ids": [self.athlete_user.id]}, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_can_update_plan(self):
        self.client.force_authenticate(user=self.coach_user)
        plan = NutritionPlan.objects.create(coach=self.coach_user, title="Plan", description="Desc")
        response = self.client.patch(f"{self.plan_url}{plan.id}/", {"title": "New"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_coach_can_delete_plan(self):
        self.client.force_authenticate(user=self.coach_user)
        plan = NutritionPlan.objects.create(coach=self.coach_user, title="Plan", description="Desc")
        response = self.client.delete(f"{self.plan_url}{plan.id}/")
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
