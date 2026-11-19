from rest_framework.permissions import BasePermission


class IsSupportOrAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.role in {"support", "admin"})


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.role == "admin")


def can_access_ticket(user, ticket):
    if user.role == "admin":
        return True
    if user.role == "support":
        return str(ticket.get("assigned_to") or "") == user.id
    return user.role == "employee" and str(ticket.get("owner_id")) == user.id