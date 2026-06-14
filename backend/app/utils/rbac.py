"""Role-Based Access Control decorator."""
from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity
from ..models.user import User


def role_required(*roles):
    """Decorator that verifies the JWT and checks the user's role."""
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            from flask_jwt_extended import verify_jwt_in_request
            verify_jwt_in_request()
            uid  = int(get_jwt_identity())
            user = User.query.get(uid)
            if not user or user.role not in roles:
                return jsonify({
                    "success": False,
                    "message": "Access denied. Insufficient permissions."
                }), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator
