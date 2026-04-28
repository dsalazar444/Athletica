import os
from typing import Any

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")

import django

django.setup()

from django.core.management import call_command
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from .models import AthleteProfile, Goal, User, WeightLog


class ProfileSettingsPersistenceTests(TestCase):
    @classmethod
    def setUpClass(cls):
        call_command("migrate", verbosity=0, interactive=False, run_syncdb=True)
        super().setUpClass()

    def setUp(self):
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

    def test_athlete_profile_patch_persists_and_get_reflects_changes(self):
        client = APIClient()
        client.force_authenticate(user=self.athlete_user)

        payload = {
            "name": "Carlos Updated",
            "age": 25,
            "height": 174,
            "weight": 73.5,
            "training_goal": "endurance",
        }
        patch_response: Any = client.patch(self.url, payload, format="json")

        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)

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

        get_response: Any = client.get(self.url)
        response_data = get_response.json()

        self.assertEqual(get_response.status_code, status.HTTP_200_OK)
        self.assertEqual(response_data["name"], "Carlos Updated")
        self.assertEqual(response_data["age"], 25)
        self.assertEqual(response_data["height"], 174)
        self.assertEqual(response_data["weight"], 73.5)
        self.assertEqual(response_data["training_goal"], "endurance")

    def test_coach_profile_patch_persists_and_get_reflects_changes(self):
        client = APIClient()
        client.force_authenticate(user=self.coach_user)

        payload = {
            "name": "Ana Coach",
            "age": 32,
            "height": 168,
            "weight": 62,
            "training_goal": "wellness",
        }
        patch_response: Any = client.patch(self.url, payload, format="json")

        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)

        self.coach_user.refresh_from_db()

        self.assertEqual(self.coach_user.first_name, "Ana Coach")
        self.assertEqual(self.coach_user.age, 32)
        self.assertEqual(self.coach_user.height, 168)
        self.assertEqual(self.coach_user.weight, 62)
        self.assertEqual(self.coach_user.training_goal, "wellness")

        get_response: Any = client.get(self.url)
        response_data = get_response.json()

        self.assertEqual(get_response.status_code, status.HTTP_200_OK)
        self.assertEqual(response_data["name"], "Ana Coach")
        self.assertEqual(response_data["age"], 32)
        self.assertEqual(response_data["height"], 168)
        self.assertEqual(response_data["weight"], 62)
        self.assertEqual(response_data["training_goal"], "wellness")