
from django.urls import path
from .mobile_compat import (
    MobileLoginView, MobileRegisterView, MobileRegistrationStatusView,
    MobileTicketListCreateView, MobileTicketDetailView,
    MobileStartWorkView, MobileRecordWorkView, MobileRateTicketView,
    MobileNotificationsView, MobileNotificationReadView, MobileLogoutView,
)
from .views import (
    AdminAuditView, AdminRegistrationApproveView, AdminRegistrationRejectView,
    AdminRegistrationsView, DashboardView, HealthCheckView, LoginView, LogoutView,
    NamedResourceDetailView, NamedResourcesView, NotificationDetailView,
    NotificationsView, RegistrationView, TicketAttachmentDownloadView,
    TicketAttachmentsView, TicketAuditView, TicketCommentsView,
    TicketDetailView, TicketListCreateView, UserDetailView, UsersView,
)

urlpatterns = [
    # Compatibility endpoints matching the current Flutter ticket/user models.
    path("mobile/auth/login/", MobileLoginView.as_view(), name="mobile-login"),
    path("mobile/auth/register/", MobileRegisterView.as_view(), name="mobile-register"),
    path("mobile/auth/registration-status/", MobileRegistrationStatusView.as_view(), name="mobile-registration-status"),
    path("mobile/auth/logout/", MobileLogoutView.as_view(), name="mobile-logout"),
    path("mobile/tickets/", MobileTicketListCreateView.as_view(), name="mobile-tickets"),
    path("mobile/tickets/<str:ticket_number>/", MobileTicketDetailView.as_view(), name="mobile-ticket-detail"),
    path("mobile/tickets/<str:ticket_number>/start-work/", MobileStartWorkView.as_view(), name="mobile-ticket-start-work"),
    path("mobile/tickets/<str:ticket_number>/work-record/", MobileRecordWorkView.as_view(), name="mobile-ticket-work-record"),
    path("mobile/tickets/<str:ticket_number>/rating/", MobileRateTicketView.as_view(), name="mobile-ticket-rating"),
    path("mobile/notifications/", MobileNotificationsView.as_view(), name="mobile-notifications"),
    path("mobile/notifications/<str:notification_id>/", MobileNotificationReadView.as_view(), name="mobile-notification-read"),
    path("health/", HealthCheckView.as_view(), name="health-check"),
    path("v1/auth/register/", RegistrationView.as_view(), name="register"),
    path("v1/auth/login/", LoginView.as_view(), name="login"),
    path("v1/auth/logout/", LogoutView.as_view(), name="logout"),
    path("v1/registrations/", AdminRegistrationsView.as_view(), name="admin-registrations"),
    path("v1/registrations/<str:user_id>/approve/", AdminRegistrationApproveView.as_view(), name="admin-registration-approve"),
    path("v1/registrations/<str:user_id>/reject/", AdminRegistrationRejectView.as_view(), name="admin-registration-reject"),
    path("v1/users/", UsersView.as_view(), name="users"),
    path("v1/users/<str:user_id>/", UserDetailView.as_view(), name="user-detail"),
    path("v1/admin/audit/", AdminAuditView.as_view(), name="admin-audit"),
    path("v1/dashboard/", DashboardView.as_view(), name="dashboard"),
    path("v1/departments/", NamedResourcesView.as_view(), {"resource": "departments"}, name="departments"),
    path("v1/categories/", NamedResourcesView.as_view(), {"resource": "categories"}, name="categories"),
    path("v1/departments/<str:resource_id>/", NamedResourceDetailView.as_view(), {"resource": "departments"}, name="department-detail"),
    path("v1/categories/<str:resource_id>/", NamedResourceDetailView.as_view(), {"resource": "categories"}, name="category-detail"),
    path("v1/tickets/", TicketListCreateView.as_view(), name="tickets"),
    path("v1/tickets/<str:ticket_id>/", TicketDetailView.as_view(), name="ticket-detail"),
    path("v1/tickets/<str:ticket_id>/comments/", TicketCommentsView.as_view(), name="ticket-comments"),
    path("v1/tickets/<str:ticket_id>/audit/", TicketAuditView.as_view(), name="ticket-audit"),
    path("v1/tickets/<str:ticket_id>/attachments/", TicketAttachmentsView.as_view(), name="ticket-attachments"),
    path("v1/tickets/<str:ticket_id>/attachments/<str:attachment_id>/download/", TicketAttachmentDownloadView.as_view(), name="ticket-attachment-download"),
    path("v1/notifications/", NotificationsView.as_view(), name="notifications"),
    path("v1/notifications/<str:notification_id>/", NotificationDetailView.as_view(), name="notification-detail"),
]
