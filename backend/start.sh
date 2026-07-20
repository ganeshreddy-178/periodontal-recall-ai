#!/bin/bash
# Render startup script — initializes DB tables then starts gunicorn

echo "Starting Periodontal Recall AI Backend..."

# Create all tables if they don't exist
python -c "
from app import create_app
from app.extensions import db
app = create_app('production')
with app.app_context():
    db.create_all()
    print('Database tables ready.')
"

# Seed model version if empty
python -c "
from app import create_app
from app.extensions import db
from app.models.model_ver import ModelVersion
from datetime import datetime
app = create_app('production')
with app.app_context():
    if ModelVersion.query.count() == 0:
        mv = ModelVersion(
            version_tag='v1.0.0',
            model_path='/app/ai_module/models_saved/periodontal_cnn_model.h5',
            accuracy=95.30, auc_score=0.9870,
            description='VGG16 transfer-learning CNN',
            is_active=True, trained_at=datetime.utcnow()
        )
        db.session.add(mv)
        db.session.commit()
        print('Model version seeded.')
"

echo "Starting gunicorn..."
exec gunicorn --bind 0.0.0.0:$PORT --workers 2 --timeout 120 run:app
