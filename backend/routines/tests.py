from datetime import datetime

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from users.models import User
from routines.models import Routine, WorkoutSession


class WorkoutHistoryByDateRangeViewTests(TestCase):
	def setUp(self):
		self.client = APIClient()

		self.user_daniela = User.objects.create_user(
			username="daniela",
			password="test123",
			role="athlete",
		)
		self.other_user = User.objects.create_user(
			username="otro_usuario",
			password="test123",
			role="athlete",
		)

		self.routine_daniela = Routine.objects.create(
			title="Rutina Daniela",
			description="desc",
			category="strength",
			difficulty="beginner",
			created_by=self.user_daniela,
		)
		self.routine_other = Routine.objects.create(
			title="Rutina Otro",
			description="desc",
			category="cardio",
			difficulty="intermediate",
			created_by=self.other_user,
		)

		self.routine_daniela.assigned_athletes.add(self.user_daniela)
		self.routine_other.assigned_athletes.add(self.other_user)

	def test_history_filters_by_date_range_and_orders_by_date(self):
		WorkoutSession.objects.create(
			user=self.user_daniela,
			routine=self.routine_daniela,
			date=timezone.make_aware(datetime(2026, 3, 5, 9, 0, 0)),
		)
		in_range_older = WorkoutSession.objects.create(
			user=self.user_daniela,
			routine=self.routine_daniela,
			date=timezone.make_aware(datetime(2026, 3, 10, 8, 0, 0)),
		)
		in_range_newer = WorkoutSession.objects.create(
			user=self.user_daniela,
			routine=self.routine_daniela,
			date=timezone.make_aware(datetime(2026, 3, 12, 18, 0, 0)),
		)

		response = self.client.get(
			"/api/sessions/history/",
			{"start_date": "2026-03-10", "end_date": "2026-03-12"},
		)
		payload = response.json()

		self.assertEqual(response.status_code, 200)
		self.assertEqual(payload["count"], 2)
		self.assertEqual(len(payload["results"]), 2)
		self.assertEqual(payload["results"][0]["id"], in_range_older.pk)
		self.assertEqual(payload["results"][1]["id"], in_range_newer.pk)

	def test_history_does_not_return_data_from_other_users(self):
		WorkoutSession.objects.create(
			user=self.user_daniela,
			routine=self.routine_daniela,
			date=timezone.make_aware(datetime(2026, 3, 11, 10, 0, 0)),
		)
		WorkoutSession.objects.create(
			user=self.other_user,
			routine=self.routine_other,
			date=timezone.make_aware(datetime(2026, 3, 11, 11, 0, 0)),
		)

		response = self.client.get(
			"/api/sessions/history/",
			{"start_date": "2026-03-10", "end_date": "2026-03-12"},
		)
		payload = response.json()

		self.assertEqual(response.status_code, 200)
		self.assertEqual(payload["count"], 1)
		self.assertEqual(len(payload["results"]), 1)
		self.assertEqual(payload["results"][0]["routine_title"], "Rutina Daniela")

	def test_history_supports_pagination_params(self):
		for day in range(1, 6):
			WorkoutSession.objects.create(
				user=self.user_daniela,
				routine=self.routine_daniela,
				date=timezone.make_aware(datetime(2026, 3, day, 7, 0, 0)),
			)

		response = self.client.get(
			"/api/sessions/history/",
			{
				"start_date": "2026-03-01",
				"end_date": "2026-03-31",
				"page": 2,
				"page_size": 2,
			},
		)
		payload = response.json()

		self.assertEqual(response.status_code, 200)
		self.assertEqual(payload["count"], 5)
		self.assertEqual(len(payload["results"]), 2)
		self.assertIsNotNone(payload["next"])
		self.assertIsNotNone(payload["previous"])

	def test_history_returns_400_when_date_params_are_missing_or_invalid(self):
		missing_response = self.client.get("/api/sessions/history/")
		invalid_response = self.client.get(
			"/api/sessions/history/",
			{"start_date": "2026-03-15", "end_date": "invalid-date"},
		)

		self.assertEqual(missing_response.status_code, 400)
		self.assertEqual(invalid_response.status_code, 400)
