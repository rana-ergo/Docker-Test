import unittest.mock

import pytest
from redis import ConnectionError

from docker_test.app import app


@pytest.fixture
def http_client():
    return app.test_client()


@unittest.mock.patch("docker_test.app.redis")
def test_should_call_redis_incr(mock_redis, http_client):
    # Given
    mock_redis.return_value.incr.return_value = 5

    # When
    response = http_client.get("/")

    # Then
    assert response.status_code == 200
    assert response.text == "This page has been seen 5 times"
    mock_redis.return_value.incr.assert_called_once_with("page_views")


@unittest.mock.patch("docker_test.app.redis")
def test_should_handle_redis_connection_error(mock_redis, http_client):
    # Given
    mock_redis.return_value.incr.side_effect = ConnectionError

    # When
    response = http_client.get("/")

    # Then
    assert response.status_code == 500
    assert response.text == "Sorry, something went wrong"


# python -m pip install --editable ".[dev]"
# python -m pytest -v src/test/unit/
# python -m pytest -v src/test/integration
# python -m pytest -v src/test/e2e/
# --flask-url http://0.0.0.0:5000 --redis-url redis://localhost:6379
