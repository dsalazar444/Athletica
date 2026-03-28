# Athletica Backend 🐍

Backend basado en **Django** y **Django REST Framework** para la gestión de Athletica. Proporciona una API escalable para el frontend móvil.

## 🛠️ Stack Tecnológico

- **Framework**: [Django](https://www.djangoproject.com/)
- **API**: [Django REST Framework](https://www.django-rest-framework.org/)
- **Base de Datos**: [PostgreSQL](https://www.postgresql.org/)
- **Calidad**: Ruff (Linter & Formatter)
- **Despliegue**: Docker & Docker Compose

## 🚀 Ejecución con Docker (Recomendado)

Desde la raíz del repositorio, el backend ya está configurado para iniciarse con el servicio global. No obstante, si deseas ejecutarlo de forma aislada:

### 1. Variables de Entorno
Copia el archivo de ejemplo y configura tus credenciales:
```bash
cp .env.example .env
```

### 2. Iniciar Servicios
```bash
docker-compose up --build
```

### 3. Gestionar Migraciones
Las migraciones se aplican automáticamente al iniciar el contenedor. Si necesitas ejecutarlas manualmente:
```bash
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate
```

## 📂 Arquitectura de Módulos

- **`users/`**: Gestión de perfiles, autenticación JWT y roles (Atleta/Coach).
- **`routines/`**: Gestión de ejercicios, categorías y rutinas personalizadas.
- **`nutrition/`**: Registro de comidas y seguimiento calórico.


