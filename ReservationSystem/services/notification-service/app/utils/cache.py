import redis
import json
import time
import logging
from typing import Any, Optional

logger = logging.getLogger(__name__)

class NotificationCache:
    """Redis cache manager for notification service with detailed logging and statistics"""
    
    def __init__(self, redis_client: redis.Redis):
        self.client = redis_client
        self.hits = 0
        self.misses = 0
        self.sets = 0
        self.errors = 0
        self.deletes = 0
        
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache with detailed logging"""
        start_time = time.time()
        try:
            value = self.client.get(key)
            duration = time.time() - start_time
            
            if value is None:
                self.misses += 1
                logger.info(f"🔍 [CACHE MISS] Key: {key} | Duration: {duration:.4f}s")
                return None
            
            data = json.loads(value)
            self.hits += 1
            logger.info(f"✅ [CACHE HIT] Key: {key} | Duration: {duration:.4f}s | Size: {len(value)} bytes")
            return data
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE ERROR] Key: {key} | Error: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Set value in cache with TTL"""
        start_time = time.time()
        try:
            json_value = json.dumps(value, default=str)  # default=str to handle datetime
            self.client.setex(key, ttl, json_value)
            duration = time.time() - start_time
            self.sets += 1
            logger.info(f"💾 [CACHE SET] Key: {key} | TTL: {ttl}s | Duration: {duration:.4f}s | Size: {len(json_value)} bytes")
            return True
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE SET ERROR] Key: {key} | Error: {e}")
            return False
    
    def delete(self, *keys: str) -> bool:
        """Delete one or more keys from cache"""
        if not keys:
            return True
            
        start_time = time.time()
        try:
            self.client.delete(*keys)
            duration = time.time() - start_time
            self.deletes += len(keys)
            logger.info(f"🗑️  [CACHE DELETE] Keys: {keys} | Duration: {duration:.4f}s")
            return True
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE DELETE ERROR] Keys: {keys} | Error: {e}")
            return False
    
    def delete_pattern(self, pattern: str) -> bool:
        """Delete all keys matching a pattern"""
        start_time = time.time()
        try:
            keys = self.client.keys(pattern)
            if not keys:
                logger.info(f"⚠️  [CACHE DELETE PATTERN] No keys found for pattern: {pattern}")
                return True
            
            self.client.delete(*keys)
            duration = time.time() - start_time
            self.deletes += len(keys)
            logger.info(f"🗑️  [CACHE DELETE PATTERN] Pattern: {pattern} | Deleted: {len(keys)} keys | Duration: {duration:.4f}s")
            return True
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE DELETE PATTERN ERROR] Pattern: {pattern} | Error: {e}")
            return False
    
    def flush_all(self) -> bool:
        """Flush all cache"""
        start_time = time.time()
        try:
            self.client.flushdb()
            duration = time.time() - start_time
            logger.info(f"🧹 [CACHE FLUSH] All keys deleted | Duration: {duration:.4f}s")
            return True
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE FLUSH ERROR] Error: {e}")
            return False
    
    def get_all_keys(self) -> list:
        """Get all cache keys"""
        try:
            keys = self.client.keys("*")
            return [key.decode() if isinstance(key, bytes) else key for key in keys]
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE GET KEYS ERROR] Error: {e}")
            return []
    
    def get_stats(self) -> dict:
        """Get cache statistics"""
        total = self.hits + self.misses
        hit_rate = (self.hits / total * 100) if total > 0 else 0
        
        try:
            total_keys = len(self.client.keys("*"))
            connected = True
            self.client.ping()
        except:
            total_keys = 0
            connected = False
        
        return {
            "hits": self.hits,
            "misses": self.misses,
            "sets": self.sets,
            "deletes": self.deletes,
            "errors": self.errors,
            "hit_rate": round(hit_rate, 2),
            "total_keys": total_keys,
            "connected": connected
        }
    
    def print_stats(self):
        """Print cache statistics"""
        stats = self.get_stats()
        print("=" * 60)
        print("📊 NOTIFICATION SERVICE CACHE STATISTICS")
        print("=" * 60)
        print(f"✅ Cache Hits: {stats['hits']}")
        print(f"❌ Cache Misses: {stats['misses']}")
        print(f"💾 Cache Sets: {stats['sets']}")
        print(f"🗑️  Cache Deletes: {stats['deletes']}")
        print(f"⚠️  Cache Errors: {stats['errors']}")
        print(f"📈 Hit Rate: {stats['hit_rate']}%")
        print(f"🔑 Total Keys: {stats['total_keys']}")
        print(f"🔌 Connected: {stats['connected']}")
        print("=" * 60)


# Global cache instance
_cache_instance: Optional[NotificationCache] = None

def init_cache(redis_client: redis.Redis):
    """Initialize the cache"""
    global _cache_instance
    _cache_instance = NotificationCache(redis_client)
    logger.info("✅ Notification cache initialized")

def get_cache() -> Optional[NotificationCache]:
    """Get the cache instance"""
    return _cache_instance

