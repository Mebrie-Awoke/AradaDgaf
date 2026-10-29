from rest_framework.pagination import PageNumberPagination
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from .utils import json_safe


class ApiPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 100

    def get_paginated_response(self, data):
        return Response({
            "success": True,
            "data": data,
            "meta": {
                "count": self.page.paginator.count,
                "page": self.page.number,
                "page_size": self.get_page_size(self.request),
                "pages": self.page.paginator.num_pages,
            },
        })


def paginate_mongo(collection, request, query=None, sort=None, projection=None, transform=json_safe):
    try:
        page = int(request.query_params.get("page", "1"))
        page_size = int(request.query_params.get("page_size", "25"))
    except ValueError as exc:
        raise ValidationError({"pagination": "page and page_size must be integers."}) from exc
    if page < 1 or page_size < 1 or page_size > 100:
        raise ValidationError({"pagination": "page must be positive and page_size must be between 1 and 100."})
    query = query or {}
    count = collection.count_documents(query)
    cursor = collection.find(query, projection).sort(sort or [("created_at", -1)])
    documents = cursor.skip((page - 1) * page_size).limit(page_size)
    data = [transform(document) for document in documents]
    return Response({
        "success": True,
        "data": data,
        "meta": {
            "count": count,
            "page": page,
            "page_size": page_size,
            "pages": (count + page_size - 1) // page_size,
        },
    })