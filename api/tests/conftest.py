"""Shared pytest fixtures."""
import pytest


@pytest.fixture(autouse=True)
def fake_cosmos_env(monkeypatch):
    """Stub the Cosmos connection string so db.py imports cleanly."""
    monkeypatch.setenv(
        "CosmosDbConnectionString",
        "AccountEndpoint=https://fake/;AccountKey=fake;",
    )
