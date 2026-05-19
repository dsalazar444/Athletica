from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0017_alter_athleteprofile_id_alter_coachprofile_id_and_more"),
    ]

    operations = [
        migrations.CreateModel(
            name="Reminder",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "activity_type",
                    models.CharField(
                        choices=[("training", "Training"), ("nutrition", "Nutrition")],
                        max_length=20,
                    ),
                ),
                ("remind_at", models.DateTimeField()),
                ("is_active", models.BooleanField(default=True)),
                ("notified_at", models.DateTimeField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=models.deletion.CASCADE,
                        related_name="reminders",
                        to="users.user",
                    ),
                ),
            ],
            options={"ordering": ["remind_at"]},
        ),
    ]
