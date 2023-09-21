import os
from functools import cache

from flask import Flask
from redis import Redis, RedisError

app = Flask(__name__)


@app.get("/")
def index():
    try:
        page_views = redis().incr("page_views")
    except RedisError:
        print(RedisError)
        app.logger.exception("Redis Error")  # pylint: disable=E1101

        return "Sorry, something went wrong", 500
    else:
        return f"This page has been seen {page_views} times"


@cache
def redis():
    if os.getenv("REDIS_URL"):
        return Redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379"))
    return Redis(host="172.18.0.2", port="6379")
