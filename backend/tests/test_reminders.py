from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from users.models import AthleteProfile, Reminder, User

# ── Fixtures ──────────────────────────────────────────────────────────────────


@pytest.fixture
def athlete(db):
    user = User.objects.create_user(
        username="atleta1",
        password="password123",
        role="athlete",
        email="atleta1@test.com",
        timezone="America/Bogota",
    )
    AthleteProfile.objects.create(
        user=user, height=170, age=25, gender="M", activity_level="medium"
    )
    return user


@pytest.fixture
def other_athlete(db):
    user = User.objects.create_user(
        username="atleta2",
        password="password123",
        role="athlete",
        email="atleta2@test.com",
        timezone="UTC",
    )
    AthleteProfile.objects.create(user=user, height=165, age=30, gender="F", activity_level="low")
    return user


@pytest.fixture
def athlete_client(athlete):
    client = APIClient()
    client.force_authenticate(user=athlete)
    return client


@pytest.fixture
def other_athlete_client(other_athlete):
    client = APIClient()
    client.force_authenticate(user=other_athlete)
    return client


@pytest.fixture
def future_datetime():
    """Retorna una fecha/hora 24 horas en el futuro."""
    return timezone.now() + timedelta(hours=24)


@pytest.fixture
def past_datetime():
    """Retorna una fecha/hora 24 horas en el pasado."""
    return timezone.now() - timedelta(hours=24)


# ── CA1 & CA2: Crear recordatorio con fecha y hora ─────────────────────────────


@pytest.mark.django_db
def test_athlete_can_create_reminder_with_training_activity(athlete_client, future_datetime):
    """CA1 & CA2: Atleta crea recordatorio de entrenamiento con fecha/hora futura."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "training",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "none",
            "timezone": "America/Bogota",
        },
    )
    assert response.status_code == 201
    assert response.data["activity_type"] == "training"
    assert response.data["recurrence"] == "none"
    assert response.data["timezone"] == "America/Bogota"


@pytest.mark.django_db
def test_athlete_can_create_reminder_with_nutrition_activity(athlete_client, future_datetime):
    """CA3: Atleta crea recordatorio de alimentación."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "nutrition",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "none",
            "timezone": "UTC",
        },
    )
    assert response.status_code == 201
    assert response.data["activity_type"] == "nutrition"


@pytest.mark.django_db
def test_athlete_can_create_daily_reminder(athlete_client, future_datetime):
    """Atleta crea recordatorio con recurrencia diaria."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "training",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "daily",
            "timezone": "America/Bogota",
        },
    )
    assert response.status_code == 201
    assert response.data["recurrence"] == "daily"


@pytest.mark.django_db
def test_athlete_can_create_weekly_reminder(athlete_client, future_datetime):
    """Atleta crea recordatorio con recurrencia semanal."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "nutrition",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "weekly",
            "timezone": "America/New_York",
        },
    )
    assert response.status_code == 201
    assert response.data["recurrence"] == "weekly"


@pytest.mark.django_db
def test_athlete_can_create_monthly_reminder(athlete_client, future_datetime):
    """Atleta crea recordatorio con recurrencia mensual."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "training",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "monthly",
            "timezone": "Europe/London",
        },
    )
    assert response.status_code == 201
    assert response.data["recurrence"] == "monthly"


# ── CA8: Validación de campos vacíos ──────────────────────────────────────────


@pytest.mark.django_db
def test_create_reminder_without_activity_type_fails(athlete_client, future_datetime):
    """CA8: Crear recordatorio sin tipo de actividad retorna 400."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "remind_at": future_datetime.isoformat(),
            "recurrence": "none",
        },
    )
    assert response.status_code == 400


@pytest.mark.django_db
def test_create_reminder_without_remind_at_fails(athlete_client):
    """CA8: Crear recordatorio sin fecha/hora retorna 400."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "training",
            "recurrence": "none",
        },
    )
    assert response.status_code == 400


# ── CA9: Validación de horarios pasados ───────────────────────────────────────


@pytest.mark.django_db
def test_create_reminder_with_past_datetime_fails(athlete_client, past_datetime):
    """CA9: Crear recordatorio en hora pasada retorna error."""
    response = athlete_client.post(
        "/api/reminders/",
        {
            "activity_type": "training",
            "remind_at": past_datetime.isoformat(),
            "recurrence": "none",
        },
    )
    assert response.status_code == 400


# ── CA4: Visualizar recordatorios configurados ────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_list_own_reminders(athlete_client, athlete, future_datetime):
    """CA4: Atleta puede ver sus recordatorios."""
    Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="America/Bogota",
    )
    Reminder.objects.create(
        user=athlete,
        activity_type="nutrition",
        remind_at=future_datetime + timedelta(days=1),
        recurrence="daily",
        timezone="UTC",
    )

    response = athlete_client.get("/api/reminders/")
    assert response.status_code == 200
    assert len(response.data) == 2


@pytest.mark.django_db
def test_athlete_with_no_reminders_returns_empty_list(athlete_client):
    """Atleta sin recordatorios retorna lista vacía."""
    response = athlete_client.get("/api/reminders/")
    assert response.status_code == 200
    assert response.data == []


@pytest.mark.django_db
def test_athlete_cannot_see_other_athlete_reminders(athlete_client, other_athlete, future_datetime):
    """Atleta solo ve sus propios recordatorios, no los de otros."""
    Reminder.objects.create(
        user=other_athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="UTC",
    )

    response = athlete_client.get("/api/reminders/")
    assert response.status_code == 200
    assert len(response.data) == 0


# ── CA5: Editar recordatorios ─────────────────────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_edit_reminder_time(athlete_client, athlete, future_datetime):
    """CA5: Atleta puede cambiar la hora de un recordatorio."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="America/Bogota",
    )
    new_time = future_datetime + timedelta(hours=2)

    response = athlete_client.put(
        f"/api/reminders/{reminder.id}/",
        {
            "activity_type": "training",
            "remind_at": new_time.isoformat(),
            "recurrence": "none",
            "timezone": "America/Bogota",
        },
    )
    assert response.status_code == 200
    assert response.data["remind_at"] == new_time.isoformat()


@pytest.mark.django_db
def test_athlete_can_edit_reminder_activity(athlete_client, athlete, future_datetime):
    """CA5: Atleta puede cambiar el tipo de actividad."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="UTC",
    )

    response = athlete_client.put(
        f"/api/reminders/{reminder.id}/",
        {
            "activity_type": "nutrition",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "none",
            "timezone": "UTC",
        },
    )
    assert response.status_code == 200
    assert response.data["activity_type"] == "nutrition"


@pytest.mark.django_db
def test_athlete_can_edit_reminder_recurrence(athlete_client, athlete, future_datetime):
    """CA5: Atleta puede cambiar recurrencia de un recordatorio."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="America/Bogota",
    )

    response = athlete_client.put(
        f"/api/reminders/{reminder.id}/",
        {
            "activity_type": "training",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "daily",
            "timezone": "America/Bogota",
        },
    )
    assert response.status_code == 200
    assert response.data["recurrence"] == "daily"


@pytest.mark.django_db
def test_athlete_can_edit_reminder_timezone(athlete_client, athlete, future_datetime):
    """Atleta puede cambiar zona horaria de un recordatorio."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="UTC",
    )

    response = athlete_client.put(
        f"/api/reminders/{reminder.id}/",
        {
            "activity_type": "training",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "none",
            "timezone": "America/Los_Angeles",
        },
    )
    assert response.status_code == 200
    assert response.data["timezone"] == "America/Los_Angeles"


# ── CA6: Eliminar recordatorios ───────────────────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_delete_reminder(athlete_client, athlete, future_datetime):
    """CA6: Atleta puede eliminar un recordatorio."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="UTC",
    )

    response = athlete_client.delete(f"/api/reminders/{reminder.id}/")
    assert response.status_code == 204

    # Verificar que fue eliminado
    assert not Reminder.objects.filter(id=reminder.id).exists()


@pytest.mark.django_db
def test_athlete_cannot_delete_other_athlete_reminder(
    athlete_client, other_athlete, future_datetime
):
    """Atleta no puede eliminar recordatorio de otro atleta."""
    reminder = Reminder.objects.create(
        user=other_athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="UTC",
    )

    response = athlete_client.delete(f"/api/reminders/{reminder.id}/")
    assert response.status_code == 404


# ── CA7: Notificaciones por recordatorios debido ───────────────────────────────


@pytest.mark.django_db
def test_get_due_reminders_returns_active_overdue_not_notified(
    athlete_client, athlete, past_datetime
):
    """CA7: getDueReminders retorna recordatorios activos, vencidos y no notificados."""
    # Recordatorio debido (pasado y no notificado)
    Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=past_datetime,
        recurrence="none",
        timezone="UTC",
        is_active=True,
        notified_at=None,
    )

    response = athlete_client.get("/api/reminders/due/")
    assert response.status_code == 200
    assert len(response.data) == 1
    assert response.data[0]["activity_type"] == "training"


@pytest.mark.django_db
def test_get_due_reminders_excludes_already_notified(athlete_client, athlete, past_datetime):
    """getDueReminders no retorna recordatorios ya notificados."""
    # Recordatorio que ya fue notificado
    Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=past_datetime,
        recurrence="none",
        timezone="UTC",
        is_active=True,
        notified_at=timezone.now(),
    )

    response = athlete_client.get("/api/reminders/due/")
    assert response.status_code == 200
    assert len(response.data) == 0


@pytest.mark.django_db
def test_get_due_reminders_excludes_inactive(athlete_client, athlete, past_datetime):
    """getDueReminders no retorna recordatorios inactivos."""
    Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=past_datetime,
        recurrence="none",
        timezone="UTC",
        is_active=False,
        notified_at=None,
    )

    response = athlete_client.get("/api/reminders/due/")
    assert response.status_code == 200
    assert len(response.data) == 0


@pytest.mark.django_db
def test_get_due_reminders_excludes_future(athlete_client, athlete, future_datetime):
    """getDueReminders no retorna recordatorios futuros."""
    Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
        timezone="UTC",
        is_active=True,
        notified_at=None,
    )

    response = athlete_client.get("/api/reminders/due/")
    assert response.status_code == 200
    assert len(response.data) == 0


@pytest.mark.django_db
def test_get_due_reminders_marks_as_notified(athlete_client, athlete, past_datetime):
    """getDueReminders marca los recordatorios como notificados (notified_at)."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=past_datetime,
        recurrence="none",
        timezone="UTC",
        is_active=True,
        notified_at=None,
    )

    response = athlete_client.get("/api/reminders/due/")
    assert response.status_code == 200
    assert len(response.data) == 1

    # Verificar que fue marcado como notificado
    reminder.refresh_from_db()
    assert reminder.notified_at is not None


# ── CA10: Persistencia de recordatorios ───────────────────────────────────────


@pytest.mark.django_db
def test_reminder_persists_in_database(athlete, future_datetime):
    """CA10: Recordatorio se guarda correctamente en la base de datos."""
    reminder = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="weekly",
        timezone="America/Bogota",
        is_active=True,
    )

    # Recuperar del DB y verificar
    retrieved = Reminder.objects.get(id=reminder.id)
    assert retrieved.activity_type == "training"
    assert retrieved.recurrence == "weekly"
    assert retrieved.timezone == "America/Bogota"
    assert retrieved.user == athlete


@pytest.mark.django_db
def test_multiple_reminders_persist_independently(athlete, other_athlete, future_datetime):
    """Múltiples recordatorios de diferentes atletas se guardan independientemente."""
    reminder1 = Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="daily",
        timezone="UTC",
    )
    reminder2 = Reminder.objects.create(
        user=other_athlete,
        activity_type="nutrition",
        remind_at=future_datetime + timedelta(days=1),
        recurrence="weekly",
        timezone="America/Bogota",
    )

    assert Reminder.objects.count() == 2
    assert reminder1.user == athlete
    assert reminder2.user == other_athlete


# ── Authentication & Authorization ────────────────────────────────────────────


@pytest.mark.django_db
def test_unauthenticated_user_cannot_create_reminder(future_datetime):
    """Usuario sin autenticación no puede crear recordatorio."""
    client = APIClient()
    response = client.post(
        "/api/reminders/",
        {
            "activity_type": "training",
            "remind_at": future_datetime.isoformat(),
            "recurrence": "none",
        },
    )
    assert response.status_code == 401


@pytest.mark.django_db
def test_unauthenticated_user_cannot_list_reminders():
    """Usuario sin autenticación no puede listar recordatorios."""
    client = APIClient()
    response = client.get("/api/reminders/")
    assert response.status_code == 401


@pytest.mark.django_db
def test_coach_cannot_access_athlete_reminders(athlete, future_datetime):
    """Coach no puede acceder a recordatorios de atleta (si no están vinculados)."""
    coach = User.objects.create_user(
        username="coach1",
        password="password123",
        role="coach",
        email="coach1@test.com",
    )
    client = APIClient()
    client.force_authenticate(user=coach)

    Reminder.objects.create(
        user=athlete,
        activity_type="training",
        remind_at=future_datetime,
        recurrence="none",
    )

    response = client.get("/api/reminders/")
    assert response.status_code == 200
    # Coach solo ve sus propios recordatorios (ninguno)
    assert len(response.data) == 0
