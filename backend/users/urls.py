from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from users.views import register, profile,login

urlpatterns = [
    path('api/register/', register),
    path('api/login/', login),# login
    path('api/token/refresh/', TokenRefreshView.as_view()),   # refresh
    path('api/profile/', profile),
]