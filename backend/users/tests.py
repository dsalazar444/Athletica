from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from .models import AthleteProfile, Goal, User, WeightLog


class ProfileSettingsTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.athlete_user = User.objects.create_user(
            username="athlete_profile",
            password="pass12345",  # nosec
            email="athlete_profile@test.com",
            role="athlete",
            first_name="Carlos",
        )
        self.athlete_profile = AthleteProfile.objects.create(
            user=self.athlete_user,
            height=172,
            age=24,
            gender="male",
            activity_level="medium",
        )
        WeightLog.objects.create(athlete=self.athlete_profile, weight=70)
        Goal.objects.create(
            athlete=self.athlete_profile,
            goal_type="gain_muscle",
            description="",
            is_active=True,
        )

        self.coach_user = User.objects.create_user(
            username="coach_profile",
            password="pass12345",  # nosec
            email="coach_profile@test.com",
            role="coach",
            first_name="Ana",
        )

        self.url = "/api/users/profile/settings/"

    def test_get_profile_settings_for_athlete(self):
        self.client.force_authenticate(user=self.athlete_user)

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Carlos")
        self.assertEqual(response.data["age"], 24)
        self.assertEqual(response.data["height"], 172)
        self.assertEqual(response.data["weight"], 70)
        self.assertEqual(response.data["training_goal"], "gain_muscle")

    def test_patch_profile_settings_persists_athlete_data(self):
        self.client.force_authenticate(user=self.athlete_user)

        payload = {
            "name": "Carlos Updated",
            "age": 25,
            "height": 174,
            "weight": 73.5,
            "training_goal": "endurance",
        }
        response = self.client.patch(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.athlete_user.refresh_from_db()
        self.athlete_profile.refresh_from_db()

        self.assertEqual(self.athlete_user.first_name, "Carlos Updated")
        self.assertEqual(self.athlete_profile.age, 25)
        self.assertEqual(self.athlete_profile.height, 174)
        self.assertTrue(
            WeightLog.objects.filter(athlete=self.athlete_profile, weight=73.5).exists()
        )
        self.assertTrue(
            Goal.objects.filter(
                athlete=self.athlete_profile, goal_type="endurance", is_active=True
            ).exists()
        )

    def test_patch_profile_settings_for_coach(self):
        self.client.force_authenticate(user=self.coach_user)

        payload = {
            "name": "Ana Coach",
            "age": 32,
            "height": 168,
            "weight": 62,
            "training_goal": "wellness",
        }
        response = self.client.patch(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.coach_user.refresh_from_db()
        self.assertEqual(self.coach_user.first_name, "Ana Coach")
        self.assertEqual(self.coach_user.age, 32)
        self.assertEqual(self.coach_user.height, 168)
        self.assertEqual(self.coach_user.weight, 62)
        self.assertEqual(self.coach_user.training_goal, "wellness")

    def test_patch_profile_settings_validates_types(self):
        self.client.force_authenticate(user=self.athlete_user)

        response = self.client.patch(self.url, {"age": "abc"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("age", response.data)
