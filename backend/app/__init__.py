"""
Periodontal Recall AI - Flask Application Factory
"""
import os
from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_migrate import Migrate

from .extensions import db
from .config import config_map


def create_app(config_name: str = None) -> Flask:
    """Create and configure the Flask application."""
    if config_name is None:
        config_name = os.getenv("FLASK_ENV", "development")

    app = Flask(__name__, instance_relative_config=False)
    app.config.from_object(config_map[config_name])

    # ----- Extensions -----
    db.init_app(app)
    JWTManager(app)
    Migrate(app, db)
    CORS(app, resources={r"/api/*": {"origins": "*"}},
         supports_credentials=True,
         allow_headers=["Content-Type", "Authorization"],
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])

    # ----- Blueprints -----
    from .api.auth          import auth_bp
    from .api.patients      import patients_bp
    from .api.predict       import predict_bp
    from .api.history       import history_bp
    from .api.dashboard     import dashboard_bp
    from .api.health        import health_bp
    from .api.admin         import admin_bp
    from .api.forgot_password import forgot_bp

    app.register_blueprint(auth_bp,      url_prefix="/api/auth")
    app.register_blueprint(patients_bp,  url_prefix="/api/patients")
    app.register_blueprint(predict_bp,   url_prefix="/api/predict")
    app.register_blueprint(history_bp,   url_prefix="/api/history")
    app.register_blueprint(dashboard_bp, url_prefix="/api/dashboard")
    app.register_blueprint(health_bp,    url_prefix="/api/health")
    app.register_blueprint(admin_bp,     url_prefix="/api/admin")
    app.register_blueprint(forgot_bp,    url_prefix="/api/auth")

    # ----- Upload folder -----
    upload_dir = os.path.join(app.root_path, "..", app.config["UPLOAD_FOLDER"])
    os.makedirs(upload_dir, exist_ok=True)

    return app
