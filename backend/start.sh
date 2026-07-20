#!/bin/bash
set -e

echo "=========================================="
echo " Periodontal Recall AI - Starting..."
echo "=========================================="

echo "Initializing database..."
python -c "
import os, time

for i in range(15):
    try:
        from app import create_app
        from app.extensions import db
        from app.models.model_ver import ModelVersion
        from datetime import datetime
        app = create_app('production')
        with app.app_context():
            db.create_all()
            print('Tables created OK.')
            if ModelVersion.query.count() == 0:
                mv = ModelVersion(
                    version_tag='v1.0.0',
                    model_path='ai_module/models_saved/periodontal_cnn_model.h5',
                    accuracy=95.30, auc_score=0.9870,
                    description='VGG16 transfer-learning CNN',
                    is_active=True,
                    trained_at=datetime.utcnow()
                )
                db.session.add(mv)
                db.session.commit()
                print('Model version seeded OK.')
        break
    except Exception as e:
        print(f'Attempt {i+1}/15 failed: {e}')
        time.sleep(4)
else:
    print('ERROR: Could not initialize database after 15 attempts.')
    exit(1)
"

echo "Starting gunicorn on port ${PORT:-5000}..."
exec gunicorn \
    --bind "0.0.0.0:${PORT:-5000}" \
    --workers 2 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile - \
    run:app
