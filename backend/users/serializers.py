from rest_framework import serializers
from django.contrib.auth import get_user_model


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = None  # se asigna abajo
        fields = [
            'id', 'email', 'username', 'first_name', 'last_name',
            'gender', 'age', 'weight', 'height',
            'password', 'password2',
        ]
        extra_kwargs = {'id': {'read_only': True}}

    def validate_email(self, value):
        User = get_user_model()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Este email ya está en uso.")
        return value

    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError("Las contraseñas no coinciden.")
        return data

    def create(self, validated_data):
        validated_data.pop('password2')
        User = get_user_model()
        return User.objects.create_user(**validated_data)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = None
        fields = [
            'id', 'email', 'username', 'first_name', 'last_name',
            'gender', 'age', 'weight', 'height',
        ]