from django.conf import settings
from django.http import JsonResponse


class RequestSizeLimitMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        raw_length = request.META.get("CONTENT_LENGTH")
        if raw_length:
            try:
                content_length = int(raw_length)
            except ValueError:
                return JsonResponse({"success": False, "error": {"detail": "Invalid Content-Length."}}, status=400)
            if content_length > settings.DATA_UPLOAD_MAX_MEMORY_SIZE:
                return JsonResponse({"success": False, "error": {"detail": "Request body is too large."}}, status=413)
        return self.get_response(request)