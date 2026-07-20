"""Flask configuration — supports MySQL (local) and PostgreSQL (Railway)."""
import os
from datetime import timedelta
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))


def _build_db_uri():
    """
    Priority order:
    1. DATABASE_URL (Railway PostgreSQL)
    2. MYSQL_URL / MYSQL_PRIVATE_URL (Railway MySQL)
    3. Individual DB_* env vars (local)
    """
    # Railway PostgreSQL
    db_url = os.getenv("DATABASE_URL") or os.getenv("DATABASE_PRIVATE_URL")
    if db_url:
        # Railway uses postgres:// — SQLAlchemy needs postgresql+psycopg2://
        if db_url.startswith("postgres://"):
            db_url = db_url.replace("postgres://", "postgresql+psycopg2://", 1)
        elif db_url.startswith("postgresql://"):
            db_url = db_url.replace("postgresql://", "postgresql+psycopg2://", 1)
        return db_url

    # Railway MySQL
    mysql_url = os.getenv("MYSQL_URL") or os.getenv("MYSQL_PRIVATE_URL")
    if mysql_url:
        if mysql_url.startswith("mysql://"):
            mysql_url = mysql_url.replace("mysql://", "mysql+pymysql://", 1)
        if "charset=" not in mysql_url:
            sep = "&" if "?" in mysql_url else "?"
            mysql_url += f"{sep}charset=utf8mb4"
        return mysql_url

    # Local MySQL
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
