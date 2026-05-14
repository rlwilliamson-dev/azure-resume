"""HTTP-triggered Function that increments the visitor counter."""
import json
import logging

import azure.functions as func

from db import increment_counter

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

logger = logging.getLogger(__name__)


@app.route(route="counter", methods=["GET", "POST"])
def counter(req: func.HttpRequest) -> func.HttpResponse:
    logger.info("Counter request: %s", req.method)
    try:
        new_count = increment_counter()
    except Exception:
        logger.exception("Counter increment failed")
        return func.HttpResponse(
            body=json.dumps({"error": "counter_unavailable"}),
            mimetype="application/json",
            status_code=503,
        )

    return func.HttpResponse(
        body=json.dumps({"count": new_count}),
        mimetype="application/json",
        status_code=200,
        headers={"Cache-Control": "no-store"},
    )