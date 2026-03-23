from django.urls import path
from .views import test_serializer, RegisterView
from rest_framework_simplejwt.views import TokenRefreshView,TokenObtainPairView
from .views import protected_test

urlpatterns = [
    path('test/', test_serializer),
    path('api/auth/register/', RegisterView, name='register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='login'),
    path('api/auth/refresh/',  TokenRefreshView.as_view(),     name='token_refresh'),
    path('api/auth/me/', protected_test, name='me'),
]