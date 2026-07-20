"""Flask configuration classes."""
import os
from datetime import timedelta
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))


def _build_db_uri():
    """
    Builds SQLAlchemy DB URI.
    Supports:
    - Individual env vars (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME)
    - MYSQL_URL from Railway (mysql://user:pass@host:port/db)
    """
    mysql_url = os.getenv("MYSQL_URL") or os.getenv("MYSQL_PRIVATE_URL")
    if mysql_url:
        # Railway gives mysql:// — SQLAlchemy needs mysql+pymysql://
        if mysql_url.startswith("mysql://"):
            mysql_url = mysql_url.replace("mysql://", "mysql+pymysql://", 1)
        if "charset=" not in mysql_url:
            sep = "&" if "?" in mysql_url else "?"
            mysql_url += f"{sep}charset=utf8mb4"
        return mysql_url

    host = os.getenv("DB_HOST",     "localhost")
    port = os.getenv("DB_PORT",     "3306")
    user = os.getenv("DB_USER",     "root")
    pw   = quote_plus(os.getenv("DB_PASSWORD", ""))
    name = os.getenv("DB_NAME",     "periodontal_recall_ai")
    return f"mysql+pymysql://{user}:{pw}@{host}:{port}/{name}?charset=utf8mb4"


class BaseConfig:
    SECRET_KEY         = os.getenv("SECRET_KEY",     "dev-secret-key-change-in-prod")
    JWT_SECRET_KEY     = os.getenv("JWT_SECRET_KEY", "dev-jwt-secret-change-in-prod")
    JWT_ACCESS_TOKEN_EXPIRES  = timedelta(hours=12)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_DATABASE_URI        = _build_db_uri()

    UPLOAD_FOLDER      = os.getenv("UPLOAD_FOLDER", "uploads")
    MAX_CONTENT_LENGTH = int(os.getenv("MAX_CONTENT_LENGTH", 16 * 1024 * 1024))
    ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}
    MODEL_PATH         = os.getenv("MODEL_PATH",
                         "ai_module/models_saved/periodontal_cnn_model.h5")


class DevelopmentConfig(BaseConfig):
    DEBUG = True


class ProductionConfig(BaseConfig):
    DEBUG = False


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"


config_map = {
    "development": DevelopmentConfig,
    "production":  ProductionConfig,
    "testing":     TestingConfig,
}
