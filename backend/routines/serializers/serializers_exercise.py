# Serializers allow complex data such as querysets and model instances to be converted to native Python datatypes that can then be easily rendered into JSON, XML or other content types. Serializers also provide deserialization, allowing parsed data to be converted back into complex types, after first validating the incoming data.
# transformar y validar datos
from rest_framework import serializers
from routines.models import Exercise

# convierte instancias de Exercise a JSON y viceversa
# este deberia ir en otra clase?
class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        # datos que se incluirán al convertir el modelo en un json
        fields = '__all__'
