"""Cosmos DB access layer for the visitor counter."""
import logging
import os
from typing import Optional

from azure.cosmos import CosmosClient, exceptions

logger = logging.getLogger(__name__)

DATABASE_NAME = "AzureResume"
CONTAINER_NAME = "Counter"
COUNTER_ID = "1"

_client: Optional[CosmosClient] = None


def _get_container():
    """Lazy-init the Cosmos client so import time stays fast and tests can mock."""
    global _client
    if _client is None:
        conn = os.environ["CosmosDbConnectionString"]
        _client = CosmosClient.from_connection_string(conn)
    return _client.get_database_client(DATABASE_NAME).get_container_client(CONTAINER_NAME)


def increment_counter() -> int:
    """Increment the visitor counter and return the new value.

    Creates the counter document on first call if it doesn't already exist.
    """
    container = _get_container()
    try:
        item = container.read_item(item=COUNTER_ID, partition_key=COUNTER_ID)
        item["count"] = item.get("count", 0) + 1
    except exceptions.CosmosResourceNotFoundError:
        logger.info("Counter document missing — initializing")
        item = {"id": COUNTER_ID, "count": 1}

    container.upsert_item(item)
    return item["count"]