import pytest
from rest_framework.test import APIClient

from users.models import AthleteProfile, Goal, User

# ── Fixtures ──────────────────────────────────────────────────────────────────


@pytest.fixture
def athlete(db):
    user = User.objects.create_user(
        username="atleta1",
        password="password123",
        role="athlete",
        email="atleta1@test.com",
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
    )
    AthleteProfile.objects.create(user=user, height=165, age=30, gender="F", activity_level="low")
    return user


@pytest.fixture
def athlete_client(athlete):
    client = APIClient()
    client.force_authenticate(user=athlete)
    return client


@pytest.fixture
def profile(athlete):
    return AthleteProfile.objects.get(user=athlete)


@pytest.fixture
def other_profile(other_athlete):
    return AthleteProfile.objects.get(user=other_athlete)


# ── CA1: Registrar meta con todos los campos ──────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_create_goal_with_all_fields(athlete_client):
    """Happy path: atleta crea una meta con fecha límite y valor objetivo."""
    response = athlete_client.post(
        "/api/athlete/goals/",
        {
            "goal_type": "lose_weight",
            "description": "Bajar 5kg antes del verano",
            "target_value": 70.0,
            "current_value": 75.0,
            "deadline": "2025-08-01",
        },
    )
    assert response.status_code == 201
    assert response.data["goal_type"] == "lose_weight"
    assert response.data["target_value"] == 70.0
    assert response.data["deadline"] == "2025-08-01"


@pytest.mark.django_db
def test_create_goal_without_goal_type_fails(athlete_client):
    """Flujo alternativo: crear meta sin goal_type retorna 400."""
    response = athlete_client.post(
        "/api/athlete/goals/",
        {
            "target_value": 70.0,
            "deadline": "2025-08-01",
        },
    )
    assert response.status_code == 400


# ── CA2: Listar metas ─────────────────────────────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_list_goals(athlete_client, profile):
    """Happy path: atleta puede ver sus metas registradas."""
    Goal.objects.create(athlete=profile, goal_type="gain_muscle", target_value=80.0)
    Goal.objects.create(athlete=profile, goal_type="endurance")

    response = athlete_client.get("/api/athlete/goals/")
    assert response.status_code == 200
    assert len(response.data) == 2


@pytest.mark.django_db
def test_athlete_with_no_goals_returns_empty_list(athlete_client):
    """Flujo alternativo: atleta sin metas retorna lista vacía."""
    response = athlete_client.get("/api/athlete/goals/")
    assert response.status_code == 200
    assert response.data == []


# ── CA3: Ver detalle de una meta ──────────────────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_get_goal_detail(athlete_client, profile):
    """Happy path: atleta puede ver el detalle de una meta específica."""
    goal = Goal.objects.create(
        athlete=profile,
        goal_type="lose_weight",
        target_value=70.0,
        deadline="2025-08-01",
    )
    response = athlete_client.get(f"/api/athlete/goals/{goal.id}/")
    assert response.status_code == 200
    assert response.data["goal_type"] == "lose_weight"


@pytest.mark.django_db
def test_get_nonexistent_goal_fails(athlete_client):
    """Flujo alternativo: ver meta inexistente retorna 404."""
    response = athlete_client.get("/api/athlete/goals/9999/")
    assert response.status_code == 404


# ── CA4: Editar una meta ──────────────────────────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_edit_goal(athlete_client, profile):
    """Happy path: atleta actualiza valor objetivo y fecha límite."""
    goal = Goal.objects.create(athlete=profile, goal_type="lose_weight", target_value=75.0)
    response = athlete_client.put(
        f"/api/athlete/goals/{goal.id}/",
        {
            "goal_type": "lose_weight",
            "target_value": 68.0,
            "deadline": "2025-09-01",
        },
    )
    assert response.status_code == 200
    assert response.data["target_value"] == 68.0
    assert response.data["deadline"] == "2025-09-01"


@pytest.mark.django_db
def test_athlete_cannot_edit_another_athletes_goal(athlete_client, other_profile):
    """Flujo alternativo: atleta no puede editar metas de otro atleta."""
    goal = Goal.objects.create(athlete=other_profile, goal_type="endurance")

    response = athlete_client.put(
        f"/api/athlete/goals/{goal.id}/",
        {
            "goal_type": "endurance",
            "target_value": 10.0,
        },
    )
    assert response.status_code == 404


# ── CA5: Eliminar una meta ────────────────────────────────────────────────────


@pytest.mark.django_db
def test_athlete_can_delete_goal(athlete_client, profile):
    """Happy path: atleta elimina una de sus metas."""
    goal = Goal.objects.create(athlete=profile, goal_type="wellness")

    response = athlete_client.delete(f"/api/athlete/goals/{goal.id}/")
    assert response.status_code == 204


@pytest.mark.django_db
def test_delete_nonexistent_goal_fails(athlete_client):
    """Flujo alternativo: eliminar meta inexistente retorna 404."""
    response = athlete_client.delete("/api/athlete/goals/9999/")
    assert response.status_code == 404


@pytest.mark.django_db
def test_athlete_cannot_delete_another_athletes_goal(athlete_client, other_profile):
    """Flujo alternativo: atleta no puede eliminar metas de otro atleta."""
    goal = Goal.objects.create(athlete=other_profile, goal_type="gain_muscle")

    response = athlete_client.delete(f"/api/athlete/goals/{goal.id}/")
    assert response.status_code == 404
