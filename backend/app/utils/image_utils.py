"""Image utility functions for validation and serving."""
import os
import uuid
from flask import current_app
from werkzeug.utils import secure_filename


ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}


def allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def save_upload(file_storage) -> tuple[str, str]:
    """
    Saves an uploaded file to the uploads folder.
    Returns (full_path, filename).
    """
    original = secure_filename(file_storage.filename)
    ext      = original.rsplit(".", 1)[1].lower()
    fname    = f"{uuid.uuid4().hex}.{ext}"
    upload_root = os.path.join(
        current_app.root_path, "..", current_app.config["UPLOAD_FOLDER"]
    )
    os.makedirs(upload_root, exist_ok=True)
    full_path = os.path.join(upload_root, fname)
    file_storage.save(full_path)
    return full_path, fname
