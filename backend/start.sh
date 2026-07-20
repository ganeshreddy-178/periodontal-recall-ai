#!/bin/bash
set -e
echo "Starting Periodontal Recall AI..."

python -c "
import os, time, sys
sys.path.insert(0, os.path.dirname(os.path.abspath('run.py')))

for i in range(15):
    try:
        from app import create_app
        from app.extensions import db
        from app.models.model_ver import ModelVersion
        from datetime import datetime
        app = create_app('production')
        with app.app_context():
            db.create_all()
            print('DB tables ready.')
            if ModelVersion.query.count() == 0:
                db.session.add(ModelVersion(
                    version_tag='v1.0.0',
                    model_path='ai_module/models_saved/periodontal_cnn_model.h5',
                    accuracy=95.30, auc_score=0.9870,
                    description='VGG16 CNN', is_active=True,
                    trained_at=datetime.utcnow()))
                db.session.commit()
                print('Model version seeded.')
        break
    except Exception as e:
        print(f'Attempt {i+1}/15: {e}')
        time.sleep(4)
"

exec gunicorn --bind "0.0.0.0:${PORT:-5000}" --workers 2 --timeout 120 run:app
