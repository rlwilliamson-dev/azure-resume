"""Unit tests for the visitor counter Function."""
import json
from unittest.mock import patch

import azure.functions as func
from azure.cosmos import exceptions

from function_app import counter


def _make_request(method: str = "POST") -> func.HttpRequest:
    return func.HttpRequest(
        method=method,
        body=b"",
        url="/api/counter",
        headers={},
    )


@patch("db._get_container")
def test_counter_increments_existing_value(mock_get_container):
    fake = mock_get_container.return_value
    fake.read_item.return_value = {"id": "1", "count": 41}

    resp = counter(_make_request())

    assert resp.status_code == 200
    assert json.loads(resp.get_body())["count"] == 42
    fake.upsert_item.assert_called_once()


@patch("db._get_container")
def test_counter_initializes_when_missing(mock_get_container):
    fake = mock_get_container.return_value
    fake.read_item.side_effect = exceptions.CosmosResourceNotFoundError(
        status_code=404, message="not found"
    )

    resp = counter(_make_request())

    assert resp.status_code == 200
    assert json.loads(resp.get_body())["count"] == 1
    fake.upsert_item.assert_called_once()


@patch("db._get_container")
def test_counter_returns_503_on_cosmos_error(mock_get_container):
    fake = mock_get_container.return_value
    fake.read_item.side_effect = RuntimeError("network down")

    resp = counter(_make_request())

    assert resp.status_code == 503
    assert json.loads(resp.get_body())["error"] == "counter_unavailable"


@patch("db._get_container")
def test_counter_accepts_get_and_post(mock_get_container):
    fake = mock_get_container.return_value
    fake.read_item.return_value = {"id": "1", "count": 10}

    for method in ("GET", "POST"):
        resp = counter(_make_request(method=method))
        assert resp.status_code == 200


@patch("db._get_container")
def test_counter_sets_no_cache_header(mock_get_container):
    fake = mock_get_container.return_value
    fake.read_item.return_value = {"id": "1", "count": 1}

    resp = counter(_make_request())

    assert resp.headers["Cache-Control"] == "no-store"
