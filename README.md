# 🏋️ Athletica

Athletica es una aplicación móvil enfocada en el seguimiento de entrenamientos, nutrición y progreso físico.  
El objetivo es facilitar a los usuarios el registro de rutinas, ejercicios y alimentación, permitiendo un análisis claro de su evolución física.

# 🛡️ Estado de la Integración

**Producción (`main`):**
[![Athletica CI - Main](https://github.com/dsalazar444/Athletica/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dsalazar444/Athletica/actions/workflows/ci.yml)

**Desarrollo (`dev`):**
[![Athletica CI - Dev](https://github.com/dsalazar444/Athletica/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/dsalazar444/Athletica/actions/workflows/ci.yml)

**Calidad de Código (SonarCloud):**

**Únicamente rama: Main**

[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=Athletica&metric=coverage&token=d97cb3a0cfbfcbf012a2d32534353397922c8ee5)](https://sonarcloud.io/summary/new_code?id=Athletica)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=Athletica&metric=reliability_rating&token=d97cb3a0cfbfcbf012a2d32534353397922c8ee5)](https://sonarcloud.io/summary/new_code?id=Athletica)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=Athletica&metric=sqale_rating&token=d97cb3a0cfbfcbf012a2d32534353397922c8ee5)](https://sonarcloud.io/summary/new_code?id=Athletica)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=Athletica&metric=sqale_index&token=d97cb3a0cfbfcbf012a2d32534353397922c8ee5)](https://sonarcloud.io/summary/new_code?id=Athletica)



## 👥 Equipo de trabajo 
- Daniela Salazar
- Salome Gutierrez
- Laura Marin
- Juan Pablo Gaviria
- Alejandro Arteaga

[📋 Backlog](https://github.com/users/dsalazar444/projects/3) 
[📄 Entregables P2](https://github.com/dsalazar444/Athletica/wiki/Entregables)

---

## 🚀 Objetivo del Proyecto

Desarrollar una aplicación móvil que permita:
- Registrar entrenamientos y ejercicios.
- Registrar alimentación diaria.
- Visualizar historial de actividad y métricas de progreso.
- Gestionar el perfil físico del usuario.

El proyecto se desarrolla bajo metodología ágil utilizando planificación MoSCoW y trabajo por sprints.

---

## 📂 Estructura del Repositorio

- **`backend/`**: API REST desarrollada en Django. [README Backend](./backend/README.md)
- **`frontend/`**: Aplicación móvil en Flutter (MVVM). [README Frontend](./frontend/README.md)

### Arquitectura de Módulos
- **`users/`**: Perfiles, autenticación JWT y roles.
- **`routines/`**: Ejercicios y rutinas personalizadas.
- **`nutrition/`**: Registro de comidas y seguimiento calórico.

---

## 🛠️ Tecnologías

- **Backend**: Python 3.12, Django 5.1, Django REST Framework.
- **Frontend**: Dart, Flutter 3.27+.
- **Infraestructura**: Docker, PostgreSQL.
- **CI/CD**: GitHub Actions.

---

## 🛡️ Calidad y Seguridad (CI/CD)

El proyecto utiliza **GitHub Actions** para validar cada contribución automáticamente:

### 🐍 Backend
- **Linter**: `Ruff` (PEP 8).
- **Seguridad**: `Bandit` (SAST) y `Safety` (Dependencias).
- **Tests**: Suite de Django sobre SQLite.

### 📱 Frontend
- **Análisis**: `flutter analyze`.
- **Tests**: `flutter test` (Widgets y lógica).

---

## ⚡ Inicio Rápido (Entorno de Desarrollo)

### Requisitos Previos
- Docker y Docker Compose.
- Flutter SDK.

### Levantamiento Completo (Backend + DB)
Desde la raíz del proyecto:
```bash
docker-compose up --build
```
- **API**: localhost:8000
- **DB**: localhost:5433

### Comandos de Utilidad
| Acción | Comando |
| :--- | :--- |
| Migraciones | `docker-compose exec web python manage.py migrate` |
| Superusuario | `docker-compose exec web python manage.py createsuperuser` |
| Ver Logs | `docker-compose logs -f web` |
| Tests Backend | `cd backend && python manage.py test` |
| Tests Frontend | `cd frontend && flutter test` |
