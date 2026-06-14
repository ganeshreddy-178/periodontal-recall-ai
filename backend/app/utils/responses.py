"""Standardized JSON response helpers."""
from flask import jsonify


def success(data=None, message: str = "Success", status: int = 200):
    payload = {"success": True, "message": message}
    if data is not None:
        payload["data"] = data
    return jsonify(payload), status


def error(message: str = "Error", status: int = 400, errors=None):
    payload = {"success": False, "message": message}
    if errors:
        payload["errors"] = errors
    return jsonify(payload), status


def paginated(items, total: int, page: int, per_page: int):
    return jsonify({
        "success":   True,
        "data":      items,
        "pagination": {
            "total":    total,
            "page":     page,
            "per_page": per_page,
            "pages":    (total + per_page - 1) // per_page,
        }
    }), 200
