from unittest.mock import patch, MagicMock

import pytest

from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def db_env(monkeypatch):
    """Provide fake DB env vars so the handler doesn't KeyError before reaching the mock."""
    monkeypatch.setenv("DB_HOST", "fake-host")
    monkeypatch.setenv("DB_PORT", "3306")
    monkeypatch.setenv("DB_USER", "fake-user")
    monkeypatch.setenv("DB_PASSWORD", "fake-password")
    monkeypatch.setenv("DB_NAME", "fake-db")


def test_root_returns_hello(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Hello" in response.data


def test_health_returns_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "OK"}


@patch("mysql.connector.connect")
def test_db_check_success(mock_connect, client, db_env):
    mock_cursor = MagicMock()
    mock_cursor.fetchone.return_value = (1,)

    mock_conn = MagicMock()
    mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

    mock_connect.return_value.__enter__.return_value = mock_conn

    response = client.get("/db")
    assert response.status_code == 200
    assert response.get_json() == {"db": "ok"}


@patch("mysql.connector.connect")
def test_db_check_failure(mock_connect, client, db_env):
    mock_connect.side_effect = Exception("connection refused")

    response = client.get("/db")
    assert response.status_code == 500
    body = response.get_json()
    assert body["db"] == "error"
    assert "connection refused" in body["detail"]