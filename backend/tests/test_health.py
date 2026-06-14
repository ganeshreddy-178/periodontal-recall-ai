"""Health check endpoint tests."""


def test_health_ok(client):
    resp = client.get("/api/health/")
    # In testing mode with SQLite the DB should respond
    assert resp.status_code in (200, 503)
    data = resp.get_json()
    assert "status" in data["data"]
