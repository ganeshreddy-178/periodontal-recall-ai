"""OTP generation, storage and email sending."""
import random
import string
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from typing import Optional

# In-memory OTP store  {email: {otp, expires_at}}
_otp_store: dict = {}

OTP_EXPIRY_MINUTES = 10


def generate_otp(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))


def store_otp(email: str, otp: str) -> None:
    _otp_store[email.lower()] = {
        "otp": otp,
        "expires_at": datetime.utcnow() + timedelta(minutes=OTP_EXPIRY_MINUTES),
        "attempts": 0,
    }


def verify_otp(email: str, otp: str) -> tuple[bool, str]:
    """Returns (success, message)."""
    record = _otp_store.get(email.lower())
    if not record:
        return False, "No OTP found. Please request a new one."
    if datetime.utcnow() > record["expires_at"]:
        _otp_store.pop(email.lower(), None)
        return False, "OTP has expired. Please request a new one."
    record["attempts"] += 1
    if record["attempts"] > 5:
        _otp_store.pop(email.lower(), None)
        return False, "Too many attempts. Please request a new OTP."
    if record["otp"] != otp:
        return False, f"Incorrect OTP. {5 - record['attempts']} attempts remaining."
    _otp_store.pop(email.lower(), None)
    return True, "OTP verified."


def send_otp_email(to_email: str, otp: str, name: str = "") -> tuple[bool, str]:
    """Send OTP via email. Returns (success, message)."""
    smtp_host  = os.getenv("SMTP_HOST",  "smtp.gmail.com")
    smtp_port  = int(os.getenv("SMTP_PORT",  "587"))
    smtp_user  = os.getenv("SMTP_USER",  "")
    smtp_pass  = os.getenv("SMTP_PASS",  "")
    from_email = os.getenv("SMTP_FROM",  smtp_user)

    if not smtp_user or not smtp_pass:
        # Dev mode — print OTP to console
        print(f"\n{'='*40}")
        print(f"  DEV MODE — OTP for {to_email}: {otp}")
        print(f"  Expires in {OTP_EXPIRY_MINUTES} minutes")
        print(f"{'='*40}\n")
        return True, "OTP sent (dev mode — check console)."

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "Your Periodontal Recall AI Password Reset OTP"
        msg["From"]    = f"Periodontal Recall AI <{from_email}>"
        msg["To"]      = to_email
        msg["Reply-To"] = from_email
        msg["X-Priority"] = "1"
        msg["X-Mailer"]   = "Periodontal Recall AI Mailer"
        msg["Importance"] = "High"

        html = f"""
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial, sans-serif; background:#f5f7ff; margin:0; padding:20px;">
          <div style="max-width:480px; margin:auto; background:#fff;
                      border-radius:16px; overflow:hidden;
                      box-shadow:0 4px 24px rgba(26,35,126,0.10);">
            <!-- Header -->
            <div style="background:linear-gradient(135deg,#1a237e,#3949ab,#00bcd4);
                        padding:32px 24px; text-align:center;">
              <div style="width:64px;height:64px;background:rgba(255,255,255,0.15);
                          border-radius:50%;margin:0 auto 16px;
                          display:flex;align-items:center;justify-content:center;">
                <span style="font-size:32px;">🦷</span>
              </div>
              <h1 style="color:#fff;margin:0;font-size:22px;font-weight:700;">
                Periodontal Recall AI
              </h1>
              <p style="color:rgba(255,255,255,0.8);margin:4px 0 0;font-size:13px;">
                Password Reset Request
              </p>
            </div>
            <!-- Body -->
            <div style="padding:32px 24px;">
              <p style="color:#0d1b4b;font-size:15px;margin:0 0 8px;">
                Hello{', ' + name if name else ''},
              </p>
              <p style="color:#5c6bc0;font-size:14px;line-height:1.6;">
                We received a request to reset your password.
                Use the OTP below to continue. It expires in
                <strong>{OTP_EXPIRY_MINUTES} minutes</strong>.
              </p>
              <!-- OTP Box -->
              <div style="margin:28px 0;text-align:center;">
                <div style="display:inline-block;background:#f5f7ff;
                            border:2px dashed #3949ab;border-radius:16px;
                            padding:18px 40px;">
                  <p style="margin:0 0 4px;color:#9fa8da;font-size:12px;
                             letter-spacing:2px;text-transform:uppercase;">
                    Your OTP
                  </p>
                  <p style="margin:0;color:#1a237e;font-size:40px;
                             font-weight:900;letter-spacing:12px;">
                    {otp}
                  </p>
                </div>
              </div>
              <p style="color:#9fa8da;font-size:12px;text-align:center;">
                If you didn't request this, you can safely ignore this email.
              </p>
            </div>
            <!-- Footer -->
            <div style="background:#f5f7ff;padding:16px 24px;text-align:center;">
              <p style="color:#9fa8da;font-size:11px;margin:0;">
                © 2026 Periodontal Recall AI · Secure Medical Platform
              </p>
            </div>
          </div>
        </body>
        </html>
        """

        msg.attach(MIMEText(html, "html"))

        # Plain text version (important for spam score)
        plain = f"""
Periodontal Recall AI - Password Reset OTP

Hello {name if name else 'User'},

Your OTP for password reset is: {otp}

This OTP expires in {OTP_EXPIRY_MINUTES} minutes.

If you did not request this, please ignore this email.

- Periodontal Recall AI Team
        """.strip()
        msg.attach(MIMEText(plain, "plain"))

        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.ehlo()
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(from_email, to_email, msg.as_string())

        return True, "OTP sent to your email."
    except Exception as e:
        print(f"Email error: {e}")
        return False, f"Failed to send email: {str(e)}"
