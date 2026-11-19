import os
import re

from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

TECHNICIAN_SPECIALTIES = [
    "Network",
    "Hardware",
    "Software",
    "Printers & copiers",
    "Anti-virus & security",
]


def normalize_ethiopian_phone(phone_str):
    clean = re.sub(r"[\s\-\(\)]", "", str(phone_str))
    m = re.match(r"^(\+251|251|0)?([79]\d{8})$", clean)
    if not m:
        raise serializers.ValidationError("Enter a valid Ethiopian phone number (e.g. 0911223344 or +251911223344).")
    return f"+251{m.group(2)}"


def validate_registration_password(password):
    if len(password) < 8:
        raise serializers.ValidationError("Password must be at least 8 characters long.")
    if not re.search(r"[A-Za-z]", password):
        raise serializers.ValidationError("Password must contain at least one letter.")
    if not re.search(r"\d", password):
        raise serializers.ValidationError("Password must contain at least one digit.")
    return password



class RegistrationSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=254)
    name = serializers.CharField(max_length=120, trim_whitespace=True)
    username = serializers.RegexField(regex=r"^[A-Za-z0-9_.-]{3,40}$", required=False)
    phone_number = serializers.CharField(max_length=30, required=False, allow_blank=True)
    office_location = serializers.CharField(max_length=200, required=False, allow_blank=True)
    password = serializers.CharField(min_length=12, max_length=128, write_only=True, trim_whitespace=False)

    def validate_email(self, value):
        return value.lower()

    def validate_username(self, value):
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
    department_id = serializers.CharField(max_length=24, required=False, allow_blank=True)


class TicketCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200, trim_whitespace=True)
    description = serializers.CharField(max_length=10000, trim_whitespace=True)
    priority = serializers.ChoiceField(choices=["low", "medium", "high", "critical"], default="medium")
    category_id = serializers.CharField(max_length=24, required=False, allow_blank=True)
    department_id = serializers.CharField(max_length=24, required=False, allow_blank=True)


class TicketUpdateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200, trim_whitespace=True, required=False)
    description = serializers.CharField(max_length=10000, trim_whitespace=True, required=False)
    priority = serializers.ChoiceField(choices=["low", "medium", "high", "critical"], required=False)
    status = serializers.ChoiceField(choices=["submitted", "assigned", "in_progress", "resolved", "closed"], required=False)
    assigned_to = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)
    resolution_note = serializers.CharField(max_length=5000, required=False, allow_blank=True, trim_whitespace=True)
    category_id = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)
    department_id = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)

    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError("At least one field is required.")
        return attrs


class CommentSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=5000, trim_whitespace=True)
    internal_only = serializers.BooleanField(default=False, required=False)


class NamedResourceSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100, trim_whitespace=True)
    description = serializers.CharField(max_length=500, required=False, allow_blank=True)


class AttachmentMetadataSerializer(serializers.Serializer):
    filename = serializers.CharField(max_length=255, trim_whitespace=True)
    content_type = serializers.ChoiceField(choices=["image/jpeg", "image/png"])
    size = serializers.IntegerField(min_value=1, max_value=settings.MAX_ATTACHMENT_BYTES)

    def validate_filename(self, value):
        if (
            os.path.basename(value) != value
            or "/" in value
            or "\\" in value
            or value in {".", ".."}
            or any(ord(character) < 32 or ord(character) == 127 for character in value)
        ):
            raise serializers.ValidationError("Filename must not contain a path.")
        return value


class UserUpdateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=120, trim_whitespace=True, required=False)
    role = serializers.ChoiceField(choices=["employee", "support", "admin"], required=False)
    department_id = serializers.CharField(max_length=24, required=False, allow_null=True, allow_blank=True)
    is_active = serializers.BooleanField(required=False)
    username = serializers.RegexField(regex=r"^[A-Za-z0-9_.-]{3,40}$", required=False)
    phone_number = serializers.CharField(max_length=30, required=False, allow_blank=True)
    office_location = serializers.CharField(max_length=200, required=False, allow_blank=True)

    def validate_username(self, value):
        return value.lower()

    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError("At least one field is required.")
        return attrs


class NamedResourceUpdateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100, trim_whitespace=True, required=False)
    description = serializers.CharField(max_length=500, required=False, allow_blank=True)
    is_active = serializers.BooleanField(required=False)

    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError("At least one field is required.")
        return attrs


class MobileRegistrationSerializer(serializers.Serializer):
    full_name = serializers.CharField(min_length=3, max_length=120, trim_whitespace=True)
    employee_id = serializers.RegexField(
        regex=r"^[A-Za-z0-9\-\/]{3,20}$",
        error_messages={"invalid": "Employee ID must be 3-20 characters (letters, digits, '-' or '/')."},
    )
    username = serializers.RegexField(
        regex=r"^[a-z0-9._]{4,20}$",
        error_messages={"invalid": "Username must be 4-20 lowercase letters, digits, '.' or '_'."},
    )
    phone = serializers.CharField(max_length=30, trim_whitespace=True)
    email = serializers.EmailField(max_length=254, required=False, allow_blank=True)
    department = serializers.CharField(max_length=120, trim_whitespace=True)
    work_unit = serializers.CharField(max_length=120, required=False, allow_blank=True, trim_whitespace=True)
    office_location = serializers.CharField(max_length=200, required=False, allow_blank=True, trim_whitespace=True)
    role = serializers.ChoiceField(choices=["employee", "technician"])
    password = serializers.CharField(min_length=8, max_length=128, write_only=True, trim_whitespace=False)
    confirm_password = serializers.CharField(min_length=8, max_length=128, write_only=True, required=False, trim_whitespace=False)
    specialties = serializers.ListField(
        child=serializers.ChoiceField(choices=TECHNICIAN_SPECIALTIES),
        required=False,
        allow_empty=True,
    )
    qualification_note = serializers.CharField(max_length=500, required=False, allow_blank=True, trim_whitespace=True)

    def validate_full_name(self, value):
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Full name must be at least 3 characters.")
        return value.strip()

    def validate_username(self, value):
        return value.lower().strip()

    def validate_email(self, value):
        return value.lower().strip() if value else ""

    def validate_phone(self, value):
        return normalize_ethiopian_phone(value)

    def validate_password(self, value):
        return validate_registration_password(value)

    def validate(self, attrs):
        if attrs.get("confirm_password") and attrs.get("password") != attrs.get("confirm_password"):
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        if attrs.get("role") == "technician":
            specs = attrs.get("specialties") or []
            if not specs:
                raise serializers.ValidationError({"specialties": "Technicians must select at least one specialty."})
        return attrs


class RegistrationApprovalSerializer(serializers.Serializer):
    specialties = serializers.ListField(
        child=serializers.ChoiceField(choices=TECHNICIAN_SPECIALTIES),
        required=False,
        allow_empty=True,
    )
    qualification_note = serializers.CharField(max_length=500, required=False, allow_blank=True, trim_whitespace=True)


class RegistrationRejectionSerializer(serializers.Serializer):
    reason = serializers.CharField(
        min_length=5,
        max_length=1000,
        trim_whitespace=True,
        error_messages={"min_length": "Rejection reason must be at least 5 characters."},
    )

