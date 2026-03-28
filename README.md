# 🏋️ Athletica

Athletica es una aplicación móvil enfocada en el seguimiento de entrenamientos, nutrición y progreso físico.  
El objetivo es facilitar a los usuarios el registro de rutinas, ejercicios y alimentación, permitiendo un análisis claro de su evolución física.
## Equipo de trabajo 
- Daniela Salazar
- Salome Gutierrez
- Laura Marin
- Juan Pablo Gaviria
- Alejandro Arteaga

[Backlog](https://github.com/users/dsalazar444/projects/3) 


[Entregables P2](https://github.com/dsalazar444/Athletica/wiki/Entregables)


---

## 🚀 Objetivo del Proyecto

Desarrollar una aplicación móvil que permita:

- Registrar entrenamientos y ejercicios
- Registrar alimentación diaria
- Visualizar historial de actividad
- Generar métricas básicas de progreso
- Gestionar perfil físico del usuario

El proyecto se desarrolla bajo metodología ágil utilizando planificación MoSCoW y trabajo por sprints.

---

## 📂 Estructura del Repositorio

- **`backend/`**: API REST desarrollada en Django, encargada de la lógica de negocio, autenticación JWT y persistencia de datos. [Ir al README del Backend](./backend/README.md)
- **`frontend/`**: Aplicación móvil multiplataforma desarrollada en Flutter con arquitectura MVVM. [Ir al README del Frontend](./frontend/README.md)

---

## 🚀 Inicio Rápido (Entorno de Desarrollo)

### Requisitos Previos
- **Docker** y **Docker Compose**
- **Flutter SDK** (para el desarrollo del frontend)

### Levantamiento Completo (Backend + DB)

Desde la raíz del proyecto, ejecuta:

```bash
docker-compose up --build
```

Esto levantará los siguientes servicios:
- **Port 8000**: API REST (Django)
- **Port 5433**: Base de datos (PostgreSQL)

### Comandos de Utilidad

| Acción | Comando |
| :--- | :--- |
| Crear Migraciones | `docker-compose exec web python manage.py makemigrations` |
| Aplicar Migraciones | `docker-compose exec web python manage.py migrate` |
| Crear Superusuario | `docker-compose exec web python manage.py createsuperuser` |
| Ver Logs | `docker-compose logs -f web` |

---

## 🛠️ Tecnologías

- **Backend**: Python 3.12, Django 5.1, Django REST Framework.
- **Frontend**: Dart, Flutter 3.27+.
- **Infraestructura**: Docker, PostgreSQL.
- **CI/CD**: GitHub Actions (`flutter analyze`).

---

## 📈 Estado del Proyecto
Actualmente, el flujo de **CI** valida cada commit en la rama de desarrollo antes de permitir el paso a `main`.
[![Athletica CI](https://github.com/dsalazar444/Athletica/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/dsalazar444/Athletica/actions/workflows/ci.yml)
