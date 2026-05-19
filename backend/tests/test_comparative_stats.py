from datetime import timedelta

import pytest
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from nutrition.models import MealRecord
from routines.models import Routine, WorkoutSession
from users.models import AthleteProfile, User, WeightLog


@pytest.fixture
def auth_client():
    client = APIClient()
    user = User.objects.create_user(
        username="testathlete", email="test@test.com", password="password", role="athlete"
    )
    profile = AthleteProfile.objects.create(
        user=user, age=25, height=170, gender="male", activity_level="medium"
    )
    client.force_authenticate(user=user)
    return client, user, profile


@pytest.mark.django_db
def test_comparative_stats_monthly(auth_client):
    client, user, profile = auth_client
    now = timezone.now()

    current_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    previous_start = (current_start - timedelta(days=1)).replace(day=1)

    # Add weight logs
    w1 = WeightLog.objects.create(athlete=profile, weight=70.0)
    WeightLog.objects.filter(pk=w1.pk).update(date=current_start.date() + timedelta(days=2))
    w2 = WeightLog.objects.create(athlete=profile, weight=72.0)
    WeightLog.objects.filter(pk=w2.pk).update(date=previous_start.date() + timedelta(days=2))

    # Add routine
    routine = Routine.objects.create(
        title="Test", created_by=user, category="strength", difficulty="beginner"
    )

    # Add workouts
    WorkoutSession.objects.create(
        user=user, routine=routine, date=current_start + timedelta(days=2)
    )
    WorkoutSession.objects.create(
        user=user, routine=routine, date=previous_start + timedelta(days=2)
    )
    WorkoutSession.objects.create(
        user=user, routine=routine, date=previous_start + timedelta(days=3)
    )

    # Add meals
    MealRecord.objects.create(
        athlete=profile,
        date=current_start.date() + timedelta(days=2),
        meal_type="breakfast",
        food_name="Eggs",
        portion_grams=100,
        calories=500,
        protein_g=20,
        carbs_g=50,
        fat_g=10,
    )
    MealRecord.objects.create(
        athlete=profile,
        date=previous_start.date() + timedelta(days=2),
        meal_type="breakfast",
        food_name="Eggs",
        portion_grams=100,
        calories=1000,
        protein_g=40,
        carbs_g=100,
        fat_g=20,
    )

    url = reverse("comparative_stats") + "?period=monthly"
    response = client.get(url)

    assert response.status_code == 200
    data = response.json()

    assert data["workouts"]["current"] == 1
    assert data["workouts"]["previous"] == 2
    assert data["workouts"]["change_percentage"] == -50.0

    assert data["weight_avg"]["current"] == 70.0
    assert data["weight_avg"]["previous"] == 72.0


@pytest.mark.django_db
def test_comparative_stats_quarterly(auth_client):
    client, user, profile = auth_client
    url = reverse("comparative_stats") + "?period=quarterly"
    response = client.get(url)

    assert response.status_code == 200
    data = response.json()
    assert "workouts" in data
    assert "calories_daily_avg" in data
    assert "weight_avg" in data
