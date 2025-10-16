import redis.asyncio as redis
import os
import json

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

redis_client = None

async def get_redis():
    global redis_client
    if redis_client is None:
        redis_client = await redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    return redis_client

async def cache_get(key: str):
    client = await get_redis()
    value = await client.get(key)
    return json.loads(value) if value else None

async def cache_set(key: str, value: dict, expire: int = 3600):
    client = await get_redis()
    await client.set(key, json.dumps(value), ex=expire)

async def cache_delete(key: str):
    client = await get_redis()
    await client.delete(key)

