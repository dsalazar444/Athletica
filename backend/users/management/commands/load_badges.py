"""
Management command para cargar las insignias iniciales en la base de datos.

Uso:
    python manage.py load_badges
"""

from django.core.management.base import BaseCommand

from users.models import Badge


class Command(BaseCommand):
    help = "Carga las insignias iniciales en la base de datos"

    def handle(self, *args, **options):
        # Definir todas las insignias que deben existir
        badges_data = [
            # Insignias de Alimentación
            {
                "badge_type": "alimentacion",
                "level": 1,
                "name": "Primeros Pasos en Nutrición",
                "description": "Completa tu primer día de registro de alimentación",
                "svg_filename": "alimentacion1.svg",
                "unlock_condition": "Registrar alimentación durante 1 día consecutivo",
            },
            {
                "badge_type": "alimentacion",
                "level": 3,
                "name": "Nutricionista en Formación",
                "description": "Mantén una racha de 3 días registrando tu alimentación",
                "svg_filename": "alimentacion3.svg",
                "unlock_condition": "Registrar alimentación durante 3 días consecutivos",
            },
            # Insignias de Ejercicio
            {
                "badge_type": "ejercicio",
                "level": 1,
                "name": "Primer Entrenamiento",
                "description": "Completa tu primera sesión de ejercicio",
                "svg_filename": "ejercicio1.svg",
                "unlock_condition": "Completar una sesión de ejercicio",
            },
            {
                "badge_type": "ejercicio",
                "level": 3,
                "name": "Atleta Consistente",
                "description": "Mantén una racha de 3 días de ejercicio",
                "svg_filename": "ejercicio3.svg",
                "unlock_condition": "Completar sesiones de ejercicio durante 3 días consecutivos",
            },
            {
                "badge_type": "ejercicio",
                "level": 7,
                "name": "Máquina de Entrenamiento",
                "description": "Una semana completa de entrenamiento diario",
                "svg_filename": "ejercicio7.svg",
                "unlock_condition": "Completar sesiones de ejercicio durante 7 días consecutivos",
            },
            # Insignias de Racha Completa
            {
                "badge_type": "completa",
                "level": 1,
                "name": "Equilibrio Perfecto",
                "description": "Un día con tanto ejercicio como alimentación registrada",
                "svg_filename": "completa1.svg",
                "unlock_condition": "Registrar alimentación y completar ejercicio el mismo día",
            },
            {
                "badge_type": "completa",
                "level": 3,
                "name": "Dedicación Total",
                "description": "3 días balanceando perfectamente nutrición y ejercicio",
                "svg_filename": "completa3.svg",
                "unlock_condition": "Registrar alimentación y completar ejercicio durante 3 días consecutivos",
            },
            # Insignia de Logros
            {
                "badge_type": "logros",
                "level": 3,
                "name": "Logrero",
                "description": "Desbloquea 3 insignias diferentes",
                "svg_filename": "logros3.svg",
                "unlock_condition": "Obtener un total de 3 insignias diferentes",
            },
        ]

        created_count = 0
        updated_count = 0

        for badge_info in badges_data:
            badge, created = Badge.objects.get_or_create(
                badge_type=badge_info["badge_type"],
                level=badge_info["level"],
                defaults={
                    "name": badge_info["name"],
                    "description": badge_info["description"],
                    "svg_filename": badge_info["svg_filename"],
                    "unlock_condition": badge_info["unlock_condition"],
                },
            )

            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f"✓ Insignia creada: {badge.get_badge_type_display()} - Nivel {badge.level}"
                    )
                )
            else:
                # Actualizar si los datos cambiaron
                if (
                    badge.name != badge_info["name"]
                    or badge.description != badge_info["description"]
                    or badge.svg_filename != badge_info["svg_filename"]
                    or badge.unlock_condition != badge_info["unlock_condition"]
                ):
                    badge.name = badge_info["name"]
                    badge.description = badge_info["description"]
                    badge.svg_filename = badge_info["svg_filename"]
                    badge.unlock_condition = badge_info["unlock_condition"]
                    badge.save()
                    updated_count += 1
                    self.stdout.write(
                        self.style.WARNING(
                            f"~ Insignia actualizada: {badge.get_badge_type_display()} - Nivel {badge.level}"
                        )
                    )

        self.stdout.write(self.style.SUCCESS("\n✓ Insignias cargadas exitosamente!"))
        self.stdout.write(self.style.SUCCESS(f"  Creadas: {created_count}"))
        self.stdout.write(self.style.SUCCESS(f"  Actualizadas: {updated_count}"))
