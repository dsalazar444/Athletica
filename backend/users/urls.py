from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import RegisterView, MyTokenObtainPairView, protected_test

urlpatterns = [
    # Registro de nuevos usuarios (atleta o coach).
    path('api/auth/register/', RegisterView, name='register'),

    # Login — devuelve los tokens JWT y el nombre del usuario.
    path('api/auth/login/', MyTokenObtainPairView.as_view(), name='login'),

    # Refresca el access token usando el refresh token cuando el primero expira.
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Endpoint protegido — solo accesible con un access token valido.
    path('api/auth/me/', protected_test, name='me'),
]