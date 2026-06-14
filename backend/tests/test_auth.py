"""Authentication API tests."""


def test_register(client):
    resp = client.post("/api/auth/register", json={
        "full_name": "Alice Smith",
        "email":     "alice@test.com",
        "password":  "Alice1234",
        "role":      "dentist",
    })
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["success"] is True
    assert "access_token" in data["data"]


def test_register_duplicate_email(client):
    payload = {"full_name": "Bob", "email": "bob@test.com",
               "password": "Bob12345", "role": "dentist"}
    client.post("/api/auth/register", json=payload)
    resp = client.post("/api/auth/register", json=payload)
    assert resp.status_code == 409


def test_login_success(client):
    client.post("/api/auth/register", json={
        "full_name": "Carol", "email": "carol@test.com",
        "password": "Carol123", "role": "dentist",
    })
    resp = client.post("/api/auth/login", json={
        "email": "carol@test.com", "password": "Carol123"
    })
    assert resp.status_code == 200
    assert resp.get_json()["success"] is True


def test_login_wrong_password(client):
    resp = client.post("/api/auth/login", json={
        "email": "carol@test.com", "password": "WrongPw!"
    })
    assert resp.status_code == 401


def test_me_requires_auth(client):
    resp = client.get("/api/auth/me")
    assert resp.status_code == 401


def test_me_authenticated(client, auth_headers):
    resp = client.get("/api/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.get_json()["data"]["email"] == "test@clinic.com"
