from django.urls import path
from .views import RegisterView, CustomTokenObtainPairView, protected_test
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('api/auth/register/', RegisterView, name='register'),
    path('api/auth/login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/me/', protected_test, name='me'),
]