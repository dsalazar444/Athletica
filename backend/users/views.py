from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import AthleteProfile
from .serializers import RegisterSerializer, UserSerializer, AthleteProfileSerializer
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView


# Vista temporal para probar el serializer del perfil de atleta durante el desarrollo.
# Devuelve el primer atleta registrado en la base de datos.
#@api_view(['GET'])
#def test_serializer(request):
#    athlete = AthleteProfile.objects.first()
#    serializer = AthleteProfileSerializer(athlete)
#    return Response(serializer.data)


# Vista protegida de prueba para verificar que el token JWT es valido.
# Solo accesible por usuarios autenticados.
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def protected_test(request):
    return Response({'message': f'Hola {request.user.username}, estas autenticado'})


# Vista para el registro de nuevos usuarios.
# Acepta los datos del usuario y su perfil (atleta o coach).
# Si el registro es exitoso, devuelve los tokens JWT junto con los datos del usuario.
@api_view(['POST'])
@permission_classes([AllowAny])
def RegisterView(request):
    serializer = RegisterSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()

        # Genera los tokens JWT para el usuario recien creado.
        refresh = RefreshToken.for_user(user)

        return Response({
            'user': UserSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)

    # Devuelve los errores de validacion si los datos son incorrectos.
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        try:
            athlete = AthleteProfile.objects.get(user=self.user)
            data['athlete_id'] = athlete.id
        except AthleteProfile.DoesNotExist:
            data['athlete_id'] = None
        return data


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer