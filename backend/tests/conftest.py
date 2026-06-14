"""Pytest fixtures for backend tests."""
import pytest
from app import create_app
from app.extensions import db as _db


@pytest.fixture(scope="session")
def app():
    application = create_app("testing")
    with application.app_context():
        _db.create_all()
        yield application
        _db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def auth_headers(client):
    """Register + login a test user and return JWT headers."""
    client.post("/api/auth/register", json={
        "full_name": "Test Dentist",
        "email":     "test@clinic.com",
        "password":  "Test1234",
        "role":      "dentist",
    })
    resp = client.post("/api/auth/login", json={
        "email":    "test@clinic.com",
        "password": "Test1234",
    })
    token = resp.get_json()["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}
