import redis
import json
import time
from typing import Optional, Any, Dict
import logging

logger = logging.getLogger(__name__)

class BookingCache:
    """Redis cache manager for booking service with detailed logging and statistics"""
    
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
            
        except json.JSONDecodeError as e:
            self.errors += 1
            logger.error(f"❌ [CACHE DECODE ERROR] Key: {key} | Error: {e}")
            return None
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE ERROR] Key: {key} | Error: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Set value in cache with TTL and detailed logging"""
        start_time = time.time()
        try:
            json_value = json.dumps(value)
            self.client.setex(key, ttl, json_value)
            duration = time.time() - start_time
            self.sets += 1
            logger.info(f"💾 [CACHE SET] Key: {key} | TTL: {ttl}s | Duration: {duration:.4f}s | Size: {len(json_value)} bytes")
            return True
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE SET ERROR] Key: {key} | Error: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete key from cache"""
        start_time = time.time()
        try:
            result = self.client.delete(key)
            duration = time.time() - start_time
            self.deletes += 1
            logger.info(f"🗑️  [CACHE DELETE] Key: {key} | Duration: {duration:.4f}s | Deleted: {result}")
            return result > 0
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE DELETE ERROR] Key: {key} | Error: {e}")
            return False
    
    def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern"""
        start_time = time.time()
        try:
            keys = self.client.keys(pattern)
            if keys:
                deleted = self.client.delete(*keys)
                duration = time.time() - start_time
                self.deletes += deleted
                logger.info(f"🗑️  [CACHE DELETE PATTERN] Pattern: {pattern} | Duration: {duration:.4f}s | Deleted: {deleted} keys")
                return deleted
            return 0
        except Exception as e:
            self.errors += 1
            logger.error(f"❌ [CACHE DELETE PATTERN ERROR] Pattern: {pattern} | Error: {e}")
            return 0
    
    def get_all_keys(self) -> list:
        """Get all cache keys"""
        try:
            keys = self.client.keys("*")
            return [key.decode('utf-8') if isinstance(key, bytes) else key for key in keys]
        except Exception as e:
            logger.error(f"❌ [CACHE KEYS ERROR] Error: {e}")
            return []
    
    def flush_all(self) -> bool:
        """Flush all cache"""
        try:
            self.client.flushdb()
            logger.info("🗑️  [CACHE FLUSH] All cache cleared")
            return True
        except Exception as e:
            logger.error(f"❌ [CACHE FLUSH ERROR] Error: {e}")
            return False
    
    def get_stats(self) -> Dict:
        """Get cache statistics"""
        total_requests = self.hits + self.misses
        hit_rate = (self.hits / total_requests * 100) if total_requests > 0 else 0
        
        try:
            info = self.client.info('stats')
            keyspace_hits = info.get('keyspace_hits', 0)
            keyspace_misses = info.get('keyspace_misses', 0)
            total_keys = self.client.dbsize()
            
            return {
                "hits": self.hits,
                "misses": self.misses,
                "sets": self.sets,
                "deletes": self.deletes,
                "errors": self.errors,
                "hit_rate": round(hit_rate, 2),
                "total_keys": total_keys,
                "redis_keyspace_hits": keyspace_hits,
                "redis_keyspace_misses": keyspace_misses,
                "connected": self.client.ping()
            }
        except Exception as e:
            logger.error(f"❌ [CACHE STATS ERROR] Error: {e}")
            return {
                "hits": self.hits,
                "misses": self.misses,
                "sets": self.sets,
                "deletes": self.deletes,
                "errors": self.errors,
                "hit_rate": round(hit_rate, 2),
                "connected": False
            }
    
    def print_stats(self):
        """Print cache statistics to console"""
        stats = self.get_stats()
        logger.info("=" * 60)
        logger.info("📊 BOOKING SERVICE CACHE STATISTICS")
        logger.info("=" * 60)
        logger.info(f"✅ Cache Hits: {stats['hits']}")
        logger.info(f"❌ Cache Misses: {stats['misses']}")
        logger.info(f"💾 Cache Sets: {stats['sets']}")
        logger.info(f"🗑️  Cache Deletes: {stats['deletes']}")
        logger.info(f"⚠️  Cache Errors: {stats['errors']}")
        logger.info(f"📈 Hit Rate: {stats['hit_rate']}%")
        logger.info(f"🔑 Total Keys: {stats['total_keys']}")
        logger.info(f"🔌 Connected: {stats['connected']}")
        if 'redis_keyspace_hits' in stats:
            logger.info(f"📊 Redis Keyspace Hits: {stats['redis_keyspace_hits']}")
            logger.info(f"📊 Redis Keyspace Misses: {stats['redis_keyspace_misses']}")
        logger.info("=" * 60)

# Global cache instance
booking_cache: Optional[BookingCache] = None

def init_cache(redis_client: redis.Redis):
    """Initialize global cache instance"""
    global booking_cache
    booking_cache = BookingCache(redis_client)
    logger.info("✅ Booking cache initialized")

def get_cache() -> Optional[BookingCache]:
    """Get global cache instance"""
    return booking_cache

