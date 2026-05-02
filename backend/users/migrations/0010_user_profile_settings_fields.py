# Generated manually to support profile settings fields for all user roles.

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0009_rename_experience_coachprofile_years_experience"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="age",
            field=models.IntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="user",
            name="height",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="user",
            name="weight",
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="user",
            name="training_goal",
            field=models.CharField(blank=True, default="", max_length=30),
        ),
    ]
