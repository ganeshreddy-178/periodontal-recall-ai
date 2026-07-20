#!/bin/bash
set -e

echo "=========================================="
echo " Periodontal Recall AI - Starting..."
echo "=========================================="

# Railway provides MYSQL_URL or individual vars
# Handle both cases
if [ -n "$MYSQL_URL" ]; then
    export DATABASE_URL="$MYSQL_URL"
fi

echo "Initializing database tables..."
python -c "
import os, time
# Wait for DB to be ready
for i in range(10):
    try:
        from app import create_app
        from app.extensions import db
        from app.models.model_ver import ModelVersion
        from datetime import datetime
        app = create_app('production')
        with app.app_context():
            db.create_all()
            print('Tables created.')
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
                print('Model version seeded.')
        break
    except Exception as e:
        print(f'DB not ready ({i+1}/10): {e}')
        time.sleep(3)
"

echo "Starting gunicorn on port ${PORT:-5000}..."
exec gunicorn \
    --bind "0.0.0.0:${PORT:-5000}" \
    --workers 2 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile - \
    run:app
