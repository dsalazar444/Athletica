from django.urls import path
from .views import test_serializer, RegisterView
from rest_framework_simplejwt.views import TokenRefreshView



urlpatterns = [
    path('test/', test_serializer),
    path('auth/register/', RegisterView, name='register'),
    path('auth/refresh/',  TokenRefreshView.as_view(),     name='token_refresh'),
]