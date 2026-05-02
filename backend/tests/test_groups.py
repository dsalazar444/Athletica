import pytest
from rest_framework.test import APIClient

from routines.models import TrainingGroup
from users.models import User

# ── Fixtures ──────────────────────────────────────────────────────────────────


@pytest.fixture
def coach(db):
    return User.objects.create_user(
        username="coach_groups",
        password="password123",
        role="coach",
        email="coach_groups@test.com",
    )


@pytest.fixture
def other_coach(db):
    return User.objects.create_user(
        username="other_coach",
        password="password123",
        role="coach",
        email="other_coach@test.com",
    )


@pytest.fixture
def athlete1(db):
    return User.objects.create_user(
        username="athlete1",
        password="password123",
        role="athlete",
        email="athlete1@test.com",
    )


@pytest.fixture
def athlete2(db):
    return User.objects.create_user(
        username="athlete2",
        password="password123",
        role="athlete",
        email="athlete2@test.com",
    )


@pytest.fixture
def coach_client(coach):
    client = APIClient()
    client.force_authenticate(user=coach)
    return client


# ── CA1: El entrenador puede crear un grupo ingresando al menos el nombre ─────


@pytest.mark.django_db
def test_coach_can_create_group_with_name(coach_client):
    """Happy path: coach crea un grupo con nombre válido."""
    response = coach_client.post("/api/groups/", {"name": "Grupo Fuerza"})
    assert response.status_code == 201
    assert response.data["name"] == "Grupo Fuerza"


@pytest.mark.django_db
def test_create_group_without_name_fails(coach_client):
    """Flujo alternativo: crear grupo sin nombre retorna 400."""
    response = coach_client.post("/api/groups/", {})
    assert response.status_code == 400


# ── CA2: El entrenador puede añadir atletas a un grupo existente ──────────────


@pytest.mark.django_db
def test_coach_can_add_members_to_group(coach_client, coach, athlete1, athlete2):
    """Happy path: coach añade atletas a un grupo existente."""
    group = TrainingGroup.objects.create(name="Grupo Cardio", coach=coach)

    response = coach_client.put(
        f"/api/groups/{group.id}/",
        {"name": "Grupo Cardio", "member_ids": [athlete1.id, athlete2.id]},
    )
    assert response.status_code == 200
    assert len(response.data["members"]) == 2


@pytest.mark.django_db
def test_add_members_to_nonexistent_group_fails(coach_client, athlete1):
    """Flujo alternativo: añadir atletas a un grupo que no existe retorna 404."""
    response = coach_client.put(
        "/api/groups/9999/",
        {"name": "Grupo", "member_ids": [athlete1.id]},
    )
    assert response.status_code == 404


# ── CA3: El sistema permite visualizar la lista de miembros de cada grupo ─────


@pytest.mark.django_db
def test_coach_can_view_group_members(coach_client, coach, athlete1, athlete2):
    """Happy path: coach puede ver los miembros de su grupo."""
    group = TrainingGroup.objects.create(name="Grupo Resistencia", coach=coach)
    group.members.add(athlete1, athlete2)

    response = coach_client.get(f"/api/groups/{group.id}/")
    assert response.status_code == 200
    member_ids = [m["id"] for m in response.data["members"]]
    assert athlete1.id in member_ids
    assert athlete2.id in member_ids


@pytest.mark.django_db
def test_group_with_no_members_returns_empty_list(coach_client, coach):
    """Flujo alternativo: grupo sin miembros retorna lista vacía."""
    group = TrainingGroup.objects.create(name="Grupo Vacío", coach=coach)

    response = coach_client.get(f"/api/groups/{group.id}/")
    assert response.status_code == 200
    assert response.data["members"] == []


# ── CA4: Cada grupo cuenta con opción de Gestionar para editar info y miembros ─


@pytest.mark.django_db
def test_coach_can_edit_group_name(coach_client, coach):
    """Happy path: coach edita el nombre del grupo."""
    group = TrainingGroup.objects.create(name="Nombre Viejo", coach=coach)

    response = coach_client.put(
        f"/api/groups/{group.id}/",
        {"name": "Nombre Nuevo"},
    )
    assert response.status_code == 200
    assert response.data["name"] == "Nombre Nuevo"


@pytest.mark.django_db
def test_coach_cannot_edit_other_coach_group(coach_client, other_coach):
    """Flujo alternativo: coach no puede editar grupos de otro coach."""
    group = TrainingGroup.objects.create(name="Grupo Ajeno", coach=other_coach)

    response = coach_client.put(
        f"/api/groups/{group.id}/",
        {"name": "Intento de edición"},
    )
    assert response.status_code == 404


# ── CA5: Opción visible para crear un nuevo grupo desde Mis Grupos ────────────


@pytest.mark.django_db
def test_coach_can_list_own_groups(coach_client, coach, other_coach):
    """Happy path: coach ve solo sus propios grupos."""
    TrainingGroup.objects.create(name="Grupo A", coach=coach)
    TrainingGroup.objects.create(name="Grupo B", coach=coach)
    TrainingGroup.objects.create(name="Grupo C", coach=other_coach)

    response = coach_client.get("/api/groups/")
    assert response.status_code == 200
    assert len(response.data) == 2


@pytest.mark.django_db
def test_athlete_cannot_create_group(athlete1):
    """Flujo alternativo: atleta no puede crear grupos, retorna 403."""
    client = APIClient()
    client.force_authenticate(user=athlete1)

    response = client.post("/api/groups/", {"name": "Grupo No Permitido"})
    assert response.status_code == 403
