from unittest.mock import Mock, patch

import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from routines.models import Exercise
from users.models import AthleteProfile, User


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def athlete_user(db):
    user = User.objects.create_user(
        username="athlete", email="athlete@test.com", password="password", role="athlete"
    )
    AthleteProfile.objects.create(
        user=user, height=170.0, age=25, gender="male", activity_level="medium"
    )
    return user


@pytest.fixture
def exercises(db):
    Exercise.objects.create(name="Flexiones", description="Pushups", muscle="Chest", external_id=1)
    Exercise.objects.create(name="Sentadillas", description="Squats", muscle="Legs", external_id=2)
    Exercise.objects.create(name="Dominadas", description="Pullups", muscle="Back", external_id=3)
    return Exercise.objects.all()


@pytest.mark.django_db
class TestAIRecommendations:
    def test_recommendation_endpoint_success(self, api_client, athlete_user, exercises):
        api_client.force_authenticate(user=athlete_user)
        url = reverse("exercise-recommendations")

        mock_ai_response = [
            {"exercise_name": "Flexiones", "reason": "Good for chest"},
            {"exercise_name": "Sentadillas", "reason": "Good for legs"},
        ]

        with patch(
            "routines.views.generate_exercise_recommendations", return_value=mock_ai_response
        ):
            response = api_client.post(url)

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["recommendations"]) == 2
        assert response.data["recommendations"][0]["exercise_name"] == "Flexiones"
        assert response.data["recommendations"][0]["exercise_id"] is not None

    def test_recommendation_no_profile(self, api_client, db):
        user = User.objects.create_user(
            username="no_profile", email="no@test.com", password="password", role="athlete"
        )
        api_client.force_authenticate(user=user)
        url = reverse("exercise-recommendations")

        response = api_client.post(url)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "User must be an athlete with a profile" in response.data["detail"]

    @patch("routines.ai_service._search_youtube_video", return_value="")
    @patch("routines.ai_service._get_gemini_model")
    def test_ai_service_fallback(self, mock_get_model, mock_search_video, athlete_user, exercises):
        from routines.ai_service import generate_exercise_recommendations

        mock_model = Mock()
        mock_model.generate_content.side_effect = Exception("API Error")
        mock_get_model.return_value = mock_model

        profile = athlete_user.athleteprofile
        history = []

        # Should return mock recommendations instead of crashing
        recommendations = generate_exercise_recommendations(profile, history, exercises)
        assert len(recommendations) == 3
        assert "exercise_name" in recommendations[0]
