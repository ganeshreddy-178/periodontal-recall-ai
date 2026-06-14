"""Flask configuration classes."""
import os
from datetime import timedelta
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))


def _build_db_uri():
    host = os.getenv("DB_HOST",     "localhost")
    port = os.getenv("DB_PORT",     "3306")
    user = os.getenv("DB_USER",     "root")
    pw   = quote_plus(os.getenv("DB_PASSWORD", ""))
    name = os.getenv("DB_NAME",     "periodontal_recall_ai")
    return f"mysql+pymysql://{user}:{pw}@{host}:{port}/{name}?charset=utf8mb4"


class BaseConfig:
    SECRET_KEY         = os.getenv("SECRET_KEY",     "dev-secret-key")
    JWT_SECRET_KEY     = os.getenv("JWT_SECRET_KEY", "dev-jwt-secret")
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
