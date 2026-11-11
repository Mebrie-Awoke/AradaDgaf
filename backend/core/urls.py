
from django.urls import path
from .views import (
    AdminAuditView, DashboardView, HealthCheckView, LoginView, LogoutView, NamedResourceDetailView, NamedResourcesView,
    NotificationDetailView, NotificationsView, RegistrationView,
    TicketAttachmentDownloadView, TicketAttachmentsView, TicketAuditView, TicketCommentsView,
    TicketDetailView, TicketListCreateView, UserDetailView, UsersView,
)

urlpatterns = [
    path("health/", HealthCheckView.as_view(), name="health-check"),
    path("v1/auth/register/", RegistrationView.as_view(), name="register"),
    path("v1/auth/login/", LoginView.as_view(), name="login"),
    path("v1/auth/logout/", LogoutView.as_view(), name="logout"),
    path("v1/users/", UsersView.as_view(), name="users"),
    path("v1/users/<str:user_id>/", UserDetailView.as_view(), name="user-detail"),
    path("v1/admin/audit/", AdminAuditView.as_view(), name="admin-audit"),
    path("v1/dashboard/", DashboardView.as_view(), name="dashboard"),
    path("v1/departments/", NamedResourcesView.as_view(), {"resource": "departments"}, name="departments"),
    path("v1/categories/", NamedResourcesView.as_view(), {"resource": "categories"}, name="categories"),
    path("v1/<str:resource>/<str:resource_id>/", NamedResourceDetailView.as_view(), name="named-resource-detail"),
    path("v1/tickets/", TicketListCreateView.as_view(), name="tickets"),
    path("v1/tickets/<str:ticket_id>/", TicketDetailView.as_view(), name="ticket-detail"),
    path("v1/tickets/<str:ticket_id>/comments/", TicketCommentsView.as_view(), name="ticket-comments"),
    path("v1/tickets/<str:ticket_id>/audit/", TicketAuditView.as_view(), name="ticket-audit"),
    path("v1/tickets/<str:ticket_id>/attachments/", TicketAttachmentsView.as_view(), name="ticket-attachments"),
    path("v1/tickets/<str:ticket_id>/attachments/<str:attachment_id>/download/", TicketAttachmentDownloadView.as_view(), name="ticket-attachment-download"),
    path("v1/notifications/", NotificationsView.as_view(), name="notifications"),
    path("v1/notifications/<str:notification_id>/", NotificationDetailView.as_view(), name="notification-detail"),
]
