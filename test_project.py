import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
os.chdir(os.path.join(os.path.dirname(__file__), 'backend'))

print("=" * 50)
print("Periodontal Recall AI - Project Check")
print("=" * 50)

# 1. Check packages
print("\n[1] Checking Python packages...")
try:
    import flask; print(f"    flask {flask.__version__} OK")
    import flask_jwt_extended; print(f"    flask_jwt_extended OK")
    import flask_sqlalchemy; print(f"    flask_sqlalchemy OK")
    import pymysql; print(f"    pymysql OK")
    import bcrypt; print(f"    bcrypt OK")
    import numpy; print(f"    numpy {numpy.__version__} OK")
    import cv2; print(f"    opencv {cv2.__version__} OK")
    import sklearn; print(f"    scikit-learn {sklearn.__version__} OK")
except ImportError as e:
    print(f"    MISSING: {e}")

# 2. Check .env
print("\n[2] Checking .env config...")
from dotenv import load_dotenv
load_dotenv('.env')
db_host = os.getenv('DB_HOST')
db_name = os.getenv('DB_NAME')
db_user = os.getenv('DB_USER')
db_pass = os.getenv('DB_PASSWORD')
print(f"    DB_HOST={db_host}")
print(f"    DB_NAME={db_name}")
print(f"    DB_USER={db_user}")
print(f"    DB_PASSWORD={'*' * len(db_pass) if db_pass else 'NOT SET'}")

# 3. Test DB connection
print("\n[3] Testing MySQL connection...")
try:
    import pymysql
    conn = pymysql.connect(host=db_host, user=db_user, password=db_pass, database=db_name)
    cursor = conn.cursor()
    cursor.execute("SHOW TABLES")
    tables = [row[0] for row in cursor.fetchall()]
    print(f"    Connected OK. Tables: {tables}")
    conn.close()
except Exception as e:
    print(f"    DB ERROR: {e}")

# 4. Create Flask app
print("\n[4] Creating Flask app...")
try:
    from app import create_app
    app = create_app('development')
    print("    Flask app created OK")
    print(f"    Blueprints: {list(app.blueprints.keys())}")
except Exception as e:
    print(f"    FLASK ERROR: {e}")

# 5. Check AI service
print("\n[5] Checking AI service...")
try:
    from app.services.ai_service import AIService
    ai = AIService()
    result = ai.clinical_risk_score({
        'age': 45, 'plaque_index': 2.0, 'bleeding_on_probing': 60,
        'pocket_depth': 5, 'attachment_loss': 3, 'oral_hygiene_score': 4,
        'smoking_status': 'current', 'diabetes_status': 'type2',
        'family_history': True, 'previous_periodontal': True
    })
    print(f"    Clinical risk score: {result['score']} ({result['level']})")
    recall = ai.recall_recommendation('moderate')
    print(f"    Recall for moderate: {recall['min_months']}-{recall['max_months']} months")
    fusion = ai.fuse('moderate', 91.5, result)
    print(f"    Fusion result: {fusion['final_severity']} / {fusion['final_risk_level']}")
    print("    AI Service OK")
except Exception as e:
    print(f"    AI ERROR: {e}")

print("\n" + "=" * 50)
print("CHECK COMPLETE")
print("=" * 50)
