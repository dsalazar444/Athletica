import datetime

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from users.models import AthleteProfile, User

from .models import MealRecord


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
