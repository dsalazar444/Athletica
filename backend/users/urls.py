from django.urls import path
from .views import RegisterView
from rest_framework_simplejwt.views import TokenRefreshView, TokenObtainPairView
from .views import protected_test
 
urlpatterns = [
    # Endpoint temporal para probar el serializer durante el desarrollo.
    #path('test/', test_serializer),
 
    # Registro de nuevos usuarios (atleta o coach).
    # Crea el usuario y su perfil correspondiente en una sola peticion.
    path('api/auth/register/', RegisterView, name='register'),
 
    # Login — devuelve los tokens JWT (access y refresh) para el usuario autenticado.
    path('auth/login/', TokenObtainPairView.as_view(), name='login'),
 
    # Refresca el access token usando el refresh token cuando el primero expira.
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
 
    # Endpoint protegido — solo accesible con un access token valido.
    # Usado para verificar que el usuario esta autenticado.
    path('api/auth/me/', protected_test, name='me'),
]