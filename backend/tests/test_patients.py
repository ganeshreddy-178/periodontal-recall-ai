"""Patient CRUD API tests."""
import json

PATIENT_PAYLOAD = {
    "first_name":    "Jane",
    "last_name":     "Doe",
    "date_of_birth": "1985-06-15",
    "gender":        "female",
    "phone":         "9876543210",
    "smoking_status": "never",
    "diabetes_status": "none",
}


def test_create_patient(client, auth_headers):
    resp = client.post("/api/patients/", json=PATIENT_PAYLOAD, headers=auth_headers)
    assert resp.status_code == 201
    data = resp.get_json()["data"]
    assert data["first_name"] == "Jane"


def test_list_patients(client, auth_headers):
    resp = client.get("/api/patients/", headers=auth_headers)
    assert resp.status_code == 200
    assert "data" in resp.get_json()


def test_get_patient(client, auth_headers):
    cr   = client.post("/api/patients/", json=PATIENT_PAYLOAD, headers=auth_headers)
    pid  = cr.get_json()["data"]["id"]
    resp = client.get(f"/api/patients/{pid}", headers=auth_headers)
    assert resp.status_code == 200


def test_update_patient(client, auth_headers):
    cr   = client.post("/api/patients/", json=PATIENT_PAYLOAD, headers=auth_headers)
    pid  = cr.get_json()["data"]["id"]
    resp = client.put(f"/api/patients/{pid}", json={"notes": "Updated note"}, headers=auth_headers)
    assert resp.status_code == 200
    assert resp.get_json()["data"]["notes"] == "Updated note"


def test_delete_patient(client, auth_headers):
    cr   = client.post("/api/patients/", json=PATIENT_PAYLOAD, headers=auth_headers)
    pid  = cr.get_json()["data"]["id"]
    resp = client.delete(f"/api/patients/{pid}", headers=auth_headers)
    assert resp.status_code == 200
    # Should be gone now
    resp2 = client.get(f"/api/patients/{pid}", headers=auth_headers)
    assert resp2.status_code == 404


def test_search_patients(client, auth_headers):
    client.post("/api/patients/", json=PATIENT_PAYLOAD, headers=auth_headers)
    resp = client.get("/api/patients/?q=Jane", headers=auth_headers)
    assert resp.status_code == 200
