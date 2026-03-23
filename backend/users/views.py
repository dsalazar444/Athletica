from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .models import AthleteProfile
from .serializers import RegisterSerializer, UserSerializer, AthleteProfileSerializer


@api_view(['GET'])
def test_serializer(request):
    athlete = AthleteProfile.objects.first()
    serializer = AthleteProfileSerializer(athlete)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def protected_test(request):
    return Response({"message": f"Hola {request.user.username}, estás autenticado ✅"})


@api_view(['POST'])
@permission_classes([AllowAny])
def RegisterView(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)