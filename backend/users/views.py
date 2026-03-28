from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import AthleteProfile
from .serializers import MyTokenObtainPairSerializer, RegisterSerializer, UserSerializer


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def protected_test(request):
    return Response(
        {
            "message": f"Hola {request.user.username}, estas autenticado",
            "first_name": request.user.first_name or request.user.username,
        }
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def RegisterView(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": UserSerializer(user).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        # Agrega el nombre real del usuario para mostrarlo en el saludo
        data["first_name"] = self.user.first_name or self.user.username
        try:
            athlete = AthleteProfile.objects.get(user=self.user)
            data["athlete_id"] = athlete.id
        except AthleteProfile.DoesNotExist:
            data["athlete_id"] = None
        return data


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer
