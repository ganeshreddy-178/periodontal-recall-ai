"""Forgot password — request OTP, verify OTP, reset password."""
from flask import Blueprint, request
from ..extensions import db
from ..models.user import User
from ..utils.responses import success, error
from ..utils.otp import generate_otp, store_otp, verify_otp, send_otp_email
from ..utils.validators import validate_password

forgot_bp = Blueprint("forgot", __name__)


@forgot_bp.post("/request-otp")
def request_otp():
    """Step 1 — User enters email, we send OTP."""
    data  = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()

    if not email:
        return error("Email is required.")

    user = User.query.filter_by(email=email, is_active=True).first()
    if not user:
        # Security: don't reveal whether email exists
        return success(message="If that email is registered, an OTP has been sent.")

    otp = generate_otp()
    store_otp(email, otp)
    ok, msg = send_otp_email(email, otp, name=user.full_name.split()[0])

    if not ok:
        return error(f"Could not send OTP. {msg}", 500)

    return success(message="OTP sent to your email. Check your inbox.")


@forgot_bp.post("/verify-otp")
def verify_otp_route():
    """Step 2 — Verify the OTP entered by user."""
    data  = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    otp   = (data.get("otp")   or "").strip()

    if not email or not otp:
        return error("Email and OTP are required.")

    valid, msg = verify_otp(email, otp)
    if not valid:
        return error(msg, 400)

    # Issue a short-lived reset token (store in OTP cache with special key)
    import secrets
    reset_token = secrets.token_urlsafe(32)
    store_otp(f"reset_token:{email}", reset_token)

    return success({"reset_token": reset_token}, "OTP verified. You may now reset your password.")


@forgot_bp.post("/reset-password")
def reset_password():
    """Step 3 — Set new password using the reset token."""
    data        = request.get_json(silent=True) or {}
    email       = (data.get("email")        or "").strip().lower()
    reset_token = (data.get("reset_token")  or "").strip()
    new_password = data.get("new_password") or ""

    if not email or not reset_token or not new_password:
        return error("Email, reset_token and new_password are required.")

    # Verify reset token
    valid, msg = verify_otp(f"reset_token:{email}", reset_token)
    if not valid:
        return error("Invalid or expired reset session. Please start over.", 400)

    pw_err = validate_password(new_password)
    if pw_err:
        return error(pw_err)

    user = User.query.filter_by(email=email, is_active=True).first()
    if not user:
        return error("User not found.", 404)

    user.set_password(new_password)
    db.session.commit()

    return success(message="Password reset successfully. You can now log in.")
