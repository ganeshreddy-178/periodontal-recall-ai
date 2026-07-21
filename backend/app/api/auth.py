"""Authentication endpoints."""
from datetime import datetime
from flask import Blueprint, request
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity, get_jwt
)

from ..extensions import db
from ..models.user import User
from ..utils.responses import success, error
from ..utils.validators import validate_email, validate_password
from ..utils.audit import log_action

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True) or {}
    full_name   = (data.get("full_name")   or "").strip()
    email       = (data.get("email")       or "").strip().lower()
    password    = data.get("password")     or ""
    role        = data.get("role",         "dentist")
    clinic_name = (data.get("clinic_name") or "").strip()
    phone       = (data.get("phone")       or "").strip()

    if not full_name:
        return error("full_name is required.")
    if not validate_email(email):
        return error("Invalid email address.")
    pw_err = validate_password(password)
    if pw_err:
        return error(pw_err)
    if role not in ("admin", "dentist", "staff"):
        return error("Invalid role.")

    if User.query.filter_by(email=email).first():
        return error("Email already registered.", 409)

    user = User(
        full_name   = full_name,
        email       = email,
        role        = role,
        clinic_name = clinic_name or None,
        phone       = phone or None,
    )
    user.set_password(password)
    db.session.add(user)
    db.session.commit()
    log_action(user.id, "user.register", "users", user.id)

    # Live activity log → GitHub
    from ..utils.activity_log import log_activity
    log_activity("New User Registered", f"Role: {role} | Email: {email}")

    access  = create_access_token(identity=str(user.id))
    refresh = create_refresh_token(identity=str(user.id))
    return success({"user": user.to_dict(), "access_token": access, "refresh_token": refresh},
                   "Registration successful.", 201)


@auth_bp.post("/login")
def login():
    data     = request.get_json(silent=True) or {}
    email    = (data.get("email")    or "").strip().lower()
    password = data.get("password")  or ""

    if not email or not password:
        return error("Email and password are required.")

    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return error("Invalid email or password.", 401)
    if not user.is_active:
        return error("Account is disabled.", 403)

    user.last_login_at = datetime.utcnow()
    db.session.commit()
    log_action(user.id, "user.login", "users", user.id)

    access  = create_access_token(identity=str(user.id))
    refresh = create_refresh_token(identity=str(user.id))
    return success({"user": user.to_dict(), "access_token": access, "refresh_token": refresh},
                   "Login successful.")


@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    uid    = get_jwt_identity()
    access = create_access_token(identity=uid)
    return success({"access_token": access})


@auth_bp.get("/me")
@jwt_required()
def me():
    uid  = int(get_jwt_identity())
    user = User.query.get_or_404(uid)
    return success(user.to_dict())


@auth_bp.put("/me")
@jwt_required()
def update_profile():
    uid  = int(get_jwt_identity())
    user = User.query.get_or_404(uid)
    data = request.get_json(silent=True) or {}

    if "full_name" in data:
        user.full_name = data["full_name"].strip() or user.full_name
    if "clinic_name" in data:
        user.clinic_name = data["clinic_name"].strip() or None
    if "phone" in data:
        user.phone = data["phone"].strip() or None
    if "avatar_url" in data:
        user.avatar_url = data["avatar_url"].strip() or None

    db.session.commit()
    log_action(uid, "user.profile_update", "users", uid)
    return success(user.to_dict(), "Profile updated.")


@auth_bp.post("/change-password")
@jwt_required()
def change_password():
    uid  = int(get_jwt_identity())
    user = User.query.get_or_404(uid)
    data = request.get_json(silent=True) or {}

    old_pw = data.get("old_password") or ""
    new_pw = data.get("new_password") or ""

    if not user.check_password(old_pw):
        return error("Current password is incorrect.", 401)
    pw_err = validate_password(new_pw)
    if pw_err:
        return error(pw_err)

    user.set_password(new_pw)
    db.session.commit()
    log_action(uid, "user.password_change", "users", uid)
    return success(message="Password changed successfully.")
