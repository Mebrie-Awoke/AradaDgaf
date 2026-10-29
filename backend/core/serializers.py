import os

from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers


class RegistrationSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=254)
    name = serializers.CharField(max_length=120, trim_whitespace=True)
    password = serializers.CharField(min_length=12, max_length=128, write_only=True, trim_whitespace=False)
    department_id = serializers.CharField(max_length=24, required=False, allow_blank=True)

    def validate_email(self, value):
        return value.lower()

    def validate_password(self, value):
        validate_password(value)
        return value


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(max_length=128, write_only=True, trim_whitespace=False)

    def validate_email(self, value):
        return value.lower()


class ProvisionUserSerializer(RegistrationSerializer):
    role = serializers.ChoiceField(choices=["employee", "support", "admin"])


class TicketCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200, trim_whitespace=True)
    description = serializers.CharField(max_length=10000, trim_whitespace=True)
    priority = serializers.ChoiceField(choices=["low", "normal", "high", "urgent"], default="normal")
    category_id = serializers.CharField(max_length=24, required=False, allow_blank=True)
    department_id = serializers.CharField(max_length=24, required=False, allow_blank=True)


class TicketUpdateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200, trim_whitespace=True, required=False)
    description = serializers.CharField(max_length=10000, trim_whitespace=True, required=False)
    priority = serializers.ChoiceField(choices=["low", "normal", "high", "urgent"], required=False)
    status = serializers.ChoiceField(choices=["open", "in_progress", "resolved", "closed"], required=False)
    assigned_to = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)
    category_id = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)
    department_id = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)

    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError("At least one field is required.")
        return attrs


class CommentSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=5000, trim_whitespace=True)


class NamedResourceSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100, trim_whitespace=True)
    description = serializers.CharField(max_length=500, required=False, allow_blank=True)


class AttachmentMetadataSerializer(serializers.Serializer):
    filename = serializers.CharField(max_length=255, trim_whitespace=True)
    content_type = serializers.ChoiceField(choices=[
        "application/pdf", "image/jpeg", "image/png", "text/plain",
        "application/zip", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ])
    size = serializers.IntegerField(min_value=1, max_value=settings.MAX_ATTACHMENT_BYTES)
    storage_key = serializers.CharField(max_length=512, trim_whitespace=True)

    def validate_filename(self, value):
        if os.path.basename(value) != value or "/" in value or "\\" in value or value in {".", ".."}:
            raise serializers.ValidationError("Filename must not contain a path.")
        return value

    def validate_storage_key(self, value):
        if value.startswith(("/", "\\")) or ".." in value.split("/") or "\\" in value:
            raise serializers.ValidationError("Storage key must be a relative opaque key.")
        return value