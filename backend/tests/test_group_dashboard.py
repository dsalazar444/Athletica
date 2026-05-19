import pytest
from rest_framework.test import APIClient

from routines.models import TrainingGroup
from users.models import AthleteProfile, Goal, User, WeightLog

# ── Fixtures ──────────────────────────────────────────────────────────────────


@pytest.fixture
def coach(db):
    return User.objects.create_user(
        username="coach_dashboard",
        password="password123",
        role="coach",
        email="coach_dashboard@test.com",
    )


@pytest.fixture
def other_coach(db):
    return User.objects.create_user(
        username="other_coach_dashboard",
        password="password123",
        role="coach",
        email="other_coach_dashboard@test.com",
    )


@pytest.fixture
def athlete1(db):
    user = User.objects.create_user(
        username="atleta_dash1",
        password="password123",
        role="athlete",
        email="atleta_dash1@test.com",
    )
    AthleteProfile.objects.create(
        user=user, height=170, age=25, gender="male", activity_level="medium"
    )
    return user


@pytest.fixture
def athlete2(db):
    user = User.objects.create_user(
        username="atleta_dash2",
        password="password123",
        role="athlete",
        email="atleta_dash2@test.com",
    )
    AthleteProfile.objects.create(
        user=user, height=165, age=30, gender="female", activity_level="low"
    )
    return user


@pytest.fixture
def coach_client(coach):
    client = APIClient()
    client.force_authenticate(user=coach)
    return client


@pytest.fixture
def profile1(athlete1):
    return AthleteProfile.objects.get(user=athlete1)


@pytest.fixture
def profile2(athlete2):
    return AthleteProfile.objects.get(user=athlete2)


@pytest.fixture
def group(coach, athlete1, athlete2):
    g = TrainingGroup.objects.create(name="Grupo Test", coach=coach)
    g.members.add(athlete1, athlete2)
    return g


# ── CA1: Coach puede ver el tablero de su grupo ───────────────────────────────


@pytest.mark.django_db
def test_coach_can_view_group_dashboard(coach_client, group):
    """Happy path: coach obtiene el tablero con los atletas de su grupo."""
    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    assert response.status_code == 200
    assert response.data["group_id"] == group.id
    assert response.data["group_name"] == "Grupo Test"
    assert response.data["total_members"] == 2
    assert len(response.data["athletes"]) == 2


@pytest.mark.django_db
def test_dashboard_nonexistent_group_returns_404(coach_client):
    """Flujo alternativo: tablero de grupo inexistente retorna 404."""
    response = coach_client.get("/api/groups/9999/dashboard/")
    assert response.status_code == 404


# ── CA2: El tablero muestra el último peso del atleta ─────────────────────────


@pytest.mark.django_db
def test_dashboard_shows_latest_weight(coach_client, group, profile1):
    """Happy path: el tablero muestra el último peso registrado del atleta."""
    WeightLog.objects.create(athlete=profile1, weight=80.0)
    WeightLog.objects.create(athlete=profile1, weight=78.5)

    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    assert response.status_code == 200

    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["latest_weight"]["weight"] == 78.5


@pytest.mark.django_db
def test_dashboard_athlete_with_no_weight_logs(coach_client, group, profile1):
    """Flujo alternativo: atleta sin registros de peso muestra latest_weight null."""
    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    assert response.status_code == 200

    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["latest_weight"] is None
    assert athlete_data["weight_trend"] == "no_data"


# ── CA3: El tablero muestra la tendencia de peso ──────────────────────────────


@pytest.mark.django_db
def test_dashboard_weight_trend_down(coach_client, group, profile1):
    """Happy path: tendencia baja cuando el peso más reciente es menor."""
    WeightLog.objects.create(athlete=profile1, weight=82.0)
    WeightLog.objects.create(athlete=profile1, weight=79.0)

    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["weight_trend"] == "down"


@pytest.mark.django_db
def test_dashboard_weight_trend_up(coach_client, group, profile1):
    """Flujo alternativo: tendencia sube cuando el peso más reciente es mayor."""
    WeightLog.objects.create(athlete=profile1, weight=75.0)
    WeightLog.objects.create(athlete=profile1, weight=78.0)

    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["weight_trend"] == "up"


@pytest.mark.django_db
def test_dashboard_weight_trend_stable(coach_client, group, profile1):
    """Flujo alternativo: tendencia estable cuando el peso no cambia."""
    WeightLog.objects.create(athlete=profile1, weight=75.0)
    WeightLog.objects.create(athlete=profile1, weight=75.0)

    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["weight_trend"] == "stable"


# ── CA4: El tablero muestra la meta activa del atleta ─────────────────────────


@pytest.mark.django_db
def test_dashboard_shows_active_goal(coach_client, group, profile1):
    """Happy path: el tablero muestra la meta activa del atleta."""
    Goal.objects.create(
        athlete=profile1,
        goal_type="lose_weight",
        target_value=70.0,
        is_active=True,
    )

    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["active_goal"]["goal_type"] == "lose_weight"
    assert athlete_data["active_goal"]["target_value"] == 70.0


@pytest.mark.django_db
def test_dashboard_athlete_with_no_active_goal(coach_client, group, profile1):
    """Flujo alternativo: atleta sin meta activa muestra active_goal null."""
    response = coach_client.get(f"/api/groups/{group.id}/dashboard/")
    athlete_data = next(a for a in response.data["athletes"] if a["id"] == profile1.user.id)
    assert athlete_data["active_goal"] is None


# ── CA5: Solo el coach dueño puede ver el tablero ─────────────────────────────


@pytest.mark.django_db
def test_other_coach_cannot_view_group_dashboard(other_coach, group):
    """Flujo alternativo: otro coach no puede ver el tablero del grupo."""
    client = APIClient()
    client.force_authenticate(user=other_coach)

    response = client.get(f"/api/groups/{group.id}/dashboard/")
    assert response.status_code == 404


@pytest.mark.django_db
def test_athlete_cannot_view_group_dashboard(athlete1, group):
    """Flujo alternativo: un atleta no puede ver el tablero, retorna 403."""
    client = APIClient()
    client.force_authenticate(user=athlete1)

    response = client.get(f"/api/groups/{group.id}/dashboard/")
    assert response.status_code == 403
