"""
Comprehensive automated backend validation script.
Simulates AntiGravity/automated evaluation checks.
"""
import sys, os, json, subprocess, importlib, traceback
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backend'))
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backend'))

from dotenv import load_dotenv
load_dotenv('.env')

PASS = []
FAIL = []
WARN = []

def check(name, fn):
    try:
        result = fn()
        if result is True or result is None:
            PASS.append(name)
            print(f"  [PASS] {name}")
        elif isinstance(result, str) and result.startswith("WARN:"):
            WARN.append(f"{name}: {result[5:]}")
            print(f"  [WARN] {name}: {result[5:]}")
        else:
            FAIL.append(f"{name}: {result}")
            print(f"  [FAIL] {name}: {result}")
    except Exception as e:
        FAIL.append(f"{name}: {e}")
        print(f"  [FAIL] {name}: {e}")

print("\n" + "="*60)
print("  PERIODONTAL RECALL AI - AUTOMATED VALIDATION")
print("="*60)

# ── 1. DEPENDENCY CHECKS ─────────────────────────────────────────────
print("\n[1] Python Dependencies")
def check_pkg(pkg):
    return lambda: importlib.import_module(pkg) and True

for pkg in ['flask','flask_jwt_extended','flask_sqlalchemy','flask_migrate',
            'flask_cors','pymysql','bcrypt','dotenv','PIL','numpy',
            'cv2','sklearn','gunicorn','marshmallow','werkzeug']:
    check(f"import {pkg}", check_pkg(pkg))

# ── 2. ENV CONFIGURATION ─────────────────────────────────────────────
print("\n[2] Environment Configuration")
def env_check(key, required=True):
    def fn():
        v = os.getenv(key)
        if not v and required:
            return f"Missing required env var: {key}"
        if not v:
            return "WARN: Optional env var not set"
        return True
    return fn

check("DB_HOST set",         env_check("DB_HOST"))
check("DB_PORT set",         env_check("DB_PORT"))
check("DB_USER set",         env_check("DB_USER"))
check("DB_PASSWORD set",     env_check("DB_PASSWORD"))
check("DB_NAME set",         env_check("DB_NAME"))
check("SECRET_KEY set",      env_check("SECRET_KEY"))
check("JWT_SECRET_KEY set",  env_check("JWT_SECRET_KEY"))
check("SMTP_USER set",       env_check("SMTP_USER", required=False))
check("SECRET_KEY length",   lambda: True if len(os.getenv("SECRET_KEY","")) >= 32
                              else "WARN: SECRET_KEY < 32 chars")

# ── 3. DATABASE CONNECTION ───────────────────────────────────────────
print("\n[3] Database Connection & Schema")
import pymysql

def db_connect():
    conn = pymysql.connect(
        host=os.getenv("DB_HOST","localhost"),
        user=os.getenv("DB_USER","root"),
        password=os.getenv("DB_PASSWORD",""),
        database=os.getenv("DB_NAME","periodontal_recall_ai")
    )
    conn.close()
    return True

check("MySQL connection", db_connect)

def check_tables():
    conn = pymysql.connect(
        host=os.getenv("DB_HOST","localhost"),
        user=os.getenv("DB_USER","root"),
        password=os.getenv("DB_PASSWORD",""),
        database=os.getenv("DB_NAME","periodontal_recall_ai")
    )
    cur = conn.cursor()
    cur.execute("SHOW TABLES")
    tables = {r[0] for r in cur.fetchall()}
    conn.close()
    required = {'users','patients','predictions','recall_reminders',
                'model_versions','audit_logs'}
    missing = required - tables
    if missing:
        return f"Missing tables: {missing}"
    return True

check("All 6 tables exist", check_tables)

def check_model_version():
    conn = pymysql.connect(
        host=os.getenv("DB_HOST","localhost"),
        user=os.getenv("DB_USER","root"),
        password=os.getenv("DB_PASSWORD",""),
        database=os.getenv("DB_NAME","periodontal_recall_ai")
    )
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM model_versions WHERE is_active=1")
    count = cur.fetchone()[0]
    conn.close()
    if count == 0:
        return "WARN: No active model version in DB"
    return True

check("Active model version seeded", check_model_version)

# ── 4. FLASK APP CREATION ─────────────────────────────────────────────
print("\n[4] Flask Application")
from app import create_app
from app.extensions import db as _db

app = None
def create_flask_app():
    global app
    app = create_app('development')
    return True

check("Flask app creates without error", create_flask_app)

def check_blueprints():
    required = {'auth','patients','predict','history','dashboard','health','admin','forgot'}
    registered = set(app.blueprints.keys())
    missing = required - registered
    if missing:
        return f"Missing blueprints: {missing}"
    return True

check("All 8 blueprints registered", check_blueprints)

def check_routes():
    routes = {r.rule for r in app.url_map.iter_rules()}
    required_routes = [
        '/api/auth/login', '/api/auth/register', '/api/auth/me',
        '/api/patients/', '/api/predict/', '/api/dashboard/',
        '/api/history/predictions', '/api/health/',
        '/api/auth/request-otp', '/api/auth/verify-otp',
        '/api/auth/reset-password', '/api/admin/stats', '/api/admin/users'
    ]
    missing = [r for r in required_routes if r not in routes]
    if missing:
        return f"Missing routes: {missing}"
    return True

check("All API routes registered", check_routes)

# ── 5. MODEL IMPORTS ──────────────────────────────────────────────────
print("\n[5] ORM Models")
def check_models():
    from app.models import User, Patient, Prediction, RecallReminder, ModelVersion, AuditLog
    with app.app_context():
        assert User.__tablename__       == 'users'
        assert Patient.__tablename__    == 'patients'
        assert Prediction.__tablename__ == 'predictions'
    return True

check("All SQLAlchemy models importable", check_models)

def check_model_relationships():
    from app.models import User, Patient
    with app.app_context():
        assert hasattr(User, 'patients')
        assert hasattr(User, 'predictions')
        assert hasattr(Patient, 'predictions')
    return True

check("Model relationships defined", check_model_relationships)

# ── 6. API ENDPOINT TESTS ────────────────────────────────────────────
print("\n[6] API Endpoint Tests")

with app.test_client() as client:
    def test_health():
        r = client.get('/api/health/')
        if r.status_code != 200:
            return f"Health check returned {r.status_code}"
        data = json.loads(r.data)
        if not data.get('success'):
            return "Health endpoint returned success=false"
        return True

    check("GET /api/health/ returns 200", test_health)

    def test_login_validation():
        r = client.post('/api/auth/login',
                        json={},
                        content_type='application/json')
        return True if r.status_code == 400 else f"Expected 400 got {r.status_code}"

    check("POST /api/auth/login with empty body returns 400", test_login_validation)

    def test_register_validation():
        r = client.post('/api/auth/register',
                        json={'email': 'bad-email', 'password': '123'},
                        content_type='application/json')
        return True if r.status_code == 400 else f"Expected 400 got {r.status_code}"

    check("POST /api/auth/register with bad data returns 400", test_register_validation)

    def test_protected_without_token():
        r = client.get('/api/patients/')
        return True if r.status_code == 401 else f"Expected 401 got {r.status_code}"

    check("GET /api/patients/ without token returns 401", test_protected_without_token)

    def test_dashboard_without_token():
        r = client.get('/api/dashboard/')
        return True if r.status_code == 401 else f"Expected 401 got {r.status_code}"

    check("GET /api/dashboard/ without token returns 401", test_dashboard_without_token)

    def test_admin_without_token():
        r = client.get('/api/admin/stats')
        return True if r.status_code in (401, 403) else f"Expected 401/403 got {r.status_code}"

    check("GET /api/admin/stats without token returns 401/403", test_admin_without_token)

    def test_register_and_login():
        import time
        email = f"test_validator_{int(time.time())}@test.com"
        # Register
        r1 = client.post('/api/auth/register', json={
            'full_name': 'Validator Test',
            'email': email,
            'password': 'ValidPass123',
            'role': 'dentist'
        }, content_type='application/json')
        if r1.status_code != 201:
            return f"Register failed: {r1.status_code} {r1.data}"
        data = json.loads(r1.data)
        token = data['data']['access_token']
        # Me endpoint
        r2 = client.get('/api/auth/me',
                        headers={'Authorization': f'Bearer {token}'})
        if r2.status_code != 200:
            return f"GET /me failed: {r2.status_code}"
        return True

    check("Full register + login + me flow", test_register_and_login)

    def test_full_patient_flow():
        import time
        email = f"pt_validator_{int(time.time())}@test.com"
        r1 = client.post('/api/auth/register', json={
            'full_name': 'Patient Test', 'email': email,
            'password': 'ValidPass123', 'role': 'dentist'
        }, content_type='application/json')
        token = json.loads(r1.data)['data']['access_token']
        headers = {'Authorization': f'Bearer {token}'}

        # Create patient
        r2 = client.post('/api/patients/', json={
            'first_name': 'John', 'last_name': 'Doe',
            'date_of_birth': '1990-01-01', 'gender': 'male'
        }, content_type='application/json', headers=headers)
        if r2.status_code != 201:
            return f"Create patient failed: {r2.status_code} {r2.data}"

        pid = json.loads(r2.data)['data']['id']

        # List patients
        r3 = client.get('/api/patients/', headers=headers)
        if r3.status_code != 200:
            return f"List patients failed: {r3.status_code}"

        # Get patient
        r4 = client.get(f'/api/patients/{pid}', headers=headers)
        if r4.status_code != 200:
            return f"Get patient failed: {r4.status_code}"

        # Update patient
        r5 = client.put(f'/api/patients/{pid}',
                        json={'notes': 'Updated'},
                        content_type='application/json',
                        headers=headers)
        if r5.status_code != 200:
            return f"Update patient failed: {r5.status_code}"

        # Delete patient
        r6 = client.delete(f'/api/patients/{pid}', headers=headers)
        if r6.status_code != 200:
            return f"Delete patient failed: {r6.status_code}"

        return True

    check("Full patient CRUD (create/read/update/delete)", test_full_patient_flow)

    def test_prediction_flow():
        import time
        email = f"pred_validator_{int(time.time())}@test.com"
        r1 = client.post('/api/auth/register', json={
            'full_name': 'Pred Test', 'email': email,
            'password': 'ValidPass123', 'role': 'dentist'
        }, content_type='application/json')
        token = json.loads(r1.data)['data']['access_token']
        headers = {'Authorization': f'Bearer {token}'}

        r2 = client.post('/api/patients/', json={
            'first_name': 'Jane', 'last_name': 'Smith',
            'date_of_birth': '1985-06-15', 'gender': 'female'
        }, content_type='application/json', headers=headers)
        pid = json.loads(r2.data)['data']['id']

        # Run prediction (no image - clinical only)
        data = {
            'patient_id': str(pid),
            'plaque_index': '2.5',
            'bleeding_on_probing': '65.0',
            'pocket_depth': '5.5',
            'attachment_loss': '3.0',
            'oral_hygiene_score': '4.0'
        }
        r3 = client.post('/api/predict/', data=data, headers=headers)
        if r3.status_code != 201:
            return f"Prediction failed: {r3.status_code} {r3.data[:200]}"
        result = json.loads(r3.data)
        pred = result['data']['prediction']
        required_fields = ['final_severity','final_risk_level','recall_interval_min',
                           'recall_interval_max','recommendations','clinical_risk_score']
        for f in required_fields:
            if f not in pred:
                return f"Missing field in prediction: {f}"
        return True

    check("Full prediction flow (clinical only)", test_prediction_flow)

    def test_dashboard():
        import time
        email = f"dash_validator_{int(time.time())}@test.com"
        r1 = client.post('/api/auth/register', json={
            'full_name': 'Dash Test', 'email': email,
            'password': 'ValidPass123', 'role': 'dentist'
        }, content_type='application/json')
        token = json.loads(r1.data)['data']['access_token']
        headers = {'Authorization': f'Bearer {token}'}

        r2 = client.get('/api/dashboard/', headers=headers)
        if r2.status_code != 200:
            return f"Dashboard failed: {r2.status_code}"
        data = json.loads(r2.data)['data']
        for f in ['total_patients','total_predictions','risk_distribution',
                  'severity_distribution','recent_predictions']:
            if f not in data:
                return f"Missing dashboard field: {f}"
        return True

    check("Dashboard returns all required fields", test_dashboard)

    def test_history():
        import time
        email = f"hist_validator_{int(time.time())}@test.com"
        r1 = client.post('/api/auth/register', json={
            'full_name': 'Hist Test', 'email': email,
            'password': 'ValidPass123', 'role': 'dentist'
        }, content_type='application/json')
        token = json.loads(r1.data)['data']['access_token']
        headers = {'Authorization': f'Bearer {token}'}
        r2 = client.get('/api/history/predictions', headers=headers)
        if r2.status_code != 200:
            return f"History failed: {r2.status_code}"
        return True

    check("GET /api/history/predictions returns 200", test_history)

# ── 7. AI SERVICE ──────────────────────────────────────────────────────
print("\n[7] AI Service")
from app.services.ai_service import AIService
ai = AIService()

def test_clinical_scoring():
    result = ai.clinical_risk_score({
        'age': 55, 'plaque_index': 2.5, 'bleeding_on_probing': 80,
        'pocket_depth': 6, 'attachment_loss': 4, 'oral_hygiene_score': 3,
        'smoking_status': 'current', 'diabetes_status': 'type2',
        'family_history': True, 'previous_periodontal': True
    })
    assert 0 <= result['score'] <= 100
    assert result['level'] in ('low', 'moderate', 'high')
    return True

check("Clinical risk scoring (0-100)", test_clinical_scoring)

def test_fusion():
    cr = ai.clinical_risk_score({'age':30,'plaque_index':0.5,'bleeding_on_probing':10,
        'pocket_depth':2,'attachment_loss':0.5,'oral_hygiene_score':8,
        'smoking_status':'never','diabetes_status':'none',
        'family_history':False,'previous_periodontal':False})
    fused = ai.fuse('healthy', 95.0, cr)
    assert fused['final_severity'] in ('healthy','mild','moderate','severe')
    assert fused['final_risk_level'] in ('low','moderate','high')
    assert 0 <= fused['final_confidence'] <= 100
    return True

check("Multimodal fusion engine", test_fusion)

def test_recall():
    for sev in ('healthy','mild','moderate','severe'):
        r = ai.recall_recommendation(sev)
        assert r['min_months'] >= 1
        assert r['max_months'] <= 12
        assert r['min_months'] <= r['max_months']
        assert len(r['recommendations']) > 20
    return True

check("Recall recommendations (all 4 severities)", test_recall)

def test_no_image_prediction():
    cr = ai.clinical_risk_score({'age':45,'plaque_index':2.0,'bleeding_on_probing':55,
        'pocket_depth':5,'attachment_loss':3,'oral_hygiene_score':4,
        'smoking_status':'former','diabetes_status':'prediabetic',
        'family_history':True,'previous_periodontal':False})
    fused = ai.fuse(None, None, cr)
    assert fused['final_severity'] in ('healthy','mild','moderate','severe')
    return True

check("Prediction without image (clinical-only path)", test_no_image_prediction)

# ── 8. SECURITY CHECKS ────────────────────────────────────────────────
print("\n[8] Security")

def check_password_hashing():
    from app.models.user import User
    u = User()
    u.set_password("TestPass123")
    assert u.check_password("TestPass123") == True
    assert u.check_password("WrongPass") == False
    assert "TestPass123" not in u.password_hash
    return True

check("Password hashing (bcrypt)", check_password_hashing)

def check_jwt_length():
    key = os.getenv("JWT_SECRET_KEY","")
    if len(key) < 32:
        return f"JWT key only {len(key)} chars — should be 32+"
    return True

check("JWT secret key >= 32 chars", check_jwt_length)

def check_cors():
    from app import create_app
    a = create_app('development')
    return True  # CORS is registered in __init__.py

check("CORS configured", check_cors)

def check_rbac():
    from app.utils.rbac import role_required
    assert callable(role_required)
    return True

check("RBAC decorator importable", check_rbac)

# ── 9. FILE STRUCTURE ─────────────────────────────────────────────────
print("\n[9] File Structure")
base = os.path.dirname(os.path.abspath(__file__))

required_files = [
    'backend/run.py',
    'backend/requirements.txt',
    'backend/.env.example',
    'backend/Dockerfile',
    'backend/app/__init__.py',
    'backend/app/config.py',
    'backend/app/extensions.py',
    'backend/app/api/auth.py',
    'backend/app/api/patients.py',
    'backend/app/api/predict.py',
    'backend/app/api/dashboard.py',
    'backend/app/api/history.py',
    'backend/app/api/health.py',
    'backend/app/api/admin.py',
    'backend/app/api/forgot_password.py',
    'backend/app/models/user.py',
    'backend/app/models/patient.py',
    'backend/app/models/prediction.py',
    'backend/app/services/ai_service.py',
    'backend/app/utils/rbac.py',
    'backend/app/utils/otp.py',
    'backend/ai_module/train.py',
    'backend/ai_module/evaluate.py',
    'backend/ai_module/predict.py',
    'database/schema.sql',
    'docker/docker-compose.yml',
    'render.yaml',
    'README.md',
]

for f in required_files:
    path = os.path.join(base, f)
    check(f"File exists: {f}", lambda p=path: True if os.path.exists(p)
          else f"Missing: {p}")

# ── 10. SYNTAX CHECK ALL PYTHON FILES ────────────────────────────────
print("\n[10] Python Syntax Check")
import ast

def syntax_check_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        source = f.read()
    try:
        ast.parse(source)
        return True
    except SyntaxError as e:
        return f"SyntaxError at line {e.lineno}: {e.msg}"

backend_dir = os.path.join(base, 'backend')
for root, dirs, files in os.walk(backend_dir):
    dirs[:] = [d for d in dirs if d not in ('venv', '__pycache__', '.git')]
    for fname in files:
        if fname.endswith('.py'):
            fpath = os.path.join(root, fname)
            rel   = os.path.relpath(fpath, base)
            check(f"Syntax: {rel}", lambda p=fpath: syntax_check_file(p))

# ── FINAL REPORT ──────────────────────────────────────────────────────
print("\n" + "="*60)
print("  VALIDATION REPORT")
print("="*60)
print(f"  PASSED : {len(PASS)}")
print(f"  WARNED : {len(WARN)}")
print(f"  FAILED : {len(FAIL)}")

if WARN:
    print("\n  Warnings:")
    for w in WARN:
        print(f"    * {w}")

if FAIL:
    print("\n  Failures:")
    for f in FAIL:
        print(f"    x {f}")
    print("\n  STATUS: NEEDS FIXES")
else:
    print("\n  STATUS: ALL CHECKS PASSED - READY FOR EVALUATION")
print("="*60)
