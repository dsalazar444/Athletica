# Serializers allow complex data such as querysets and model instances to be converted to native Python datatypes that can then be easily rendered into JSON, XML or other content types. Serializers also provide deserialization, allowing parsed data to be converted back into complex types, after first validating the incoming data.
from rest_framework import serializers
from routines.models import User, Routine

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Routine # model that will be tied to this serializer
        fields = (
            'name',
            'description',
            'created_by',
            'assigned_athletes',
        ) # fields to convert to json
    
    def validate_name(self, data):
        """ Validate that user can't have more than one routine with the same name"""

        user_creator = data.get('created_by')
        name = data.get('name')
        qs = Routine.objects.filter(name=name, created_by=user_creator)

        if self.instance: # verify if data is a new routine, or is an update of an existing one
            qs = qs.exclude(pk=self.instance.pk)

        if qs.exists():
            raise serializers.ValidationError("This user already has a routine with this name.")
        
        return data
    
    def validate_assigned_athletes(self, value):
        """ Validate that all assigned users are athletes"""

        for user in value:
            if getattr(user, 'role', None) != 'athlete':
                raise serializers.ValidationError(f"User {user.username} is not an athlete.")
        return value

