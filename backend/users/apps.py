from django.apps import AppConfig


class UsersConfig(AppConfig):
    name = "users"

    def ready(self):
        """Registra los signals cuando la aplicación está lista"""
        import users.signals  # noqa: F401
