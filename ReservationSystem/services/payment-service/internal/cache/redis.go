package cache

import (
	"context"
	"encoding/json"
	"log"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis/v8"
)

type RedisCache struct {
	client *redis.Client
	hits   uint64
	misses uint64
	sets   uint64
	deletes uint64
	errors uint64
	addr   string
}

type CacheStats struct {
	Hits      uint64  `json:"hits"`
	Misses    uint64  `json:"misses"`
	Sets      uint64  `json:"sets"`
	Deletes   uint64  `json:"deletes"`
	Errors    uint64  `json:"errors"`
	HitRate   float64 `json:"hit_rate"`
	TotalKeys int64   `json:"total_keys"`
	RedisAddr string  `json:"redis_addr"`
	Connected bool    `json:"connected"`
}

func NewRedisCache(addr string) *RedisCache {
	log.Printf("🔧 Creating Redis cache connection to %s", addr)

	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolSize:     10,
		MinIdleConns: 5,
	})

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		log.Printf("❌ Failed to connect to Redis at %s: %v", addr, err)
	} else {
		log.Printf("✅ Successfully connected to Redis at %s", addr)
	}

	return &RedisCache{
		client: client,
		addr:   addr,
	}
}

func (r *RedisCache) Get(ctx context.Context, key string, dest interface{}) error {
	startTime := time.Now()
	val, err := r.client.Get(ctx, key).Result()
	duration := time.Since(startTime)

	if err != nil {
		if err == redis.Nil {
			atomic.AddUint64(&r.misses, 1)
			log.Printf("🔍 [CACHE MISS] Key: %s | Duration: %v", key, duration)
		} else {
			atomic.AddUint64(&r.errors, 1)
			log.Printf("❌ [CACHE ERROR] Key: %s | Error: %v | Duration: %v", key, err, duration)
		}
		return err
	}

	if err := json.Unmarshal([]byte(val), dest); err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE UNMARSHAL ERROR] Key: %s | Error: %v", key, err)
		return err
	}

	atomic.AddUint64(&r.hits, 1)
	log.Printf("✅ [CACHE HIT] Key: %s | Duration: %v | Size: %d bytes", key, duration, len(val))
	return nil
}

func (r *RedisCache) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	startTime := time.Now()
	data, err := json.Marshal(value)
	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE MARSHAL ERROR] Key: %s | Error: %v", key, err)
		return err
	}

	if err := r.client.Set(ctx, key, data, expiration).Err(); err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE SET ERROR] Key: %s | Error: %v", key, err)
		return err
	}

	atomic.AddUint64(&r.sets, 1)
	duration := time.Since(startTime)
	log.Printf("💾 [CACHE SET] Key: %s | TTL: %v | Duration: %v | Size: %d bytes", key, expiration, duration, len(data))
	return nil
}

func (r *RedisCache) Delete(ctx context.Context, keys ...string) error {
	if len(keys) == 0 {
		return nil
	}

	startTime := time.Now()
	err := r.client.Del(ctx, keys...).Err()
	duration := time.Since(startTime)

	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE DELETE ERROR] Keys: %v | Error: %v", keys, err)
		return err
	}

	atomic.AddUint64(&r.deletes, uint64(len(keys)))
	log.Printf("🗑️  [CACHE DELETE] Keys: %v | Duration: %v", keys, duration)
	return nil
}

func (r *RedisCache) DeletePattern(ctx context.Context, pattern string) error {
	startTime := time.Now()
	
	keys, err := r.client.Keys(ctx, pattern).Result()
	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE DELETE PATTERN ERROR] Pattern: %s | Error: %v", pattern, err)
		return err
	}

	if len(keys) == 0 {
		log.Printf("⚠️  [CACHE DELETE PATTERN] No keys found for pattern: %s", pattern)
		return nil
	}

	err = r.client.Del(ctx, keys...).Err()
	duration := time.Since(startTime)

	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE DELETE PATTERN ERROR] Pattern: %s | Error: %v", pattern, err)
		return err
	}

	atomic.AddUint64(&r.deletes, uint64(len(keys)))
	log.Printf("🗑️  [CACHE DELETE PATTERN] Pattern: %s | Deleted: %d keys | Duration: %v", pattern, len(keys), duration)
	return nil
}

func (r *RedisCache) FlushAll(ctx context.Context) error {
	startTime := time.Now()
	err := r.client.FlushDB(ctx).Err()
	duration := time.Since(startTime)

	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE FLUSH ERROR] Error: %v", err)
		return err
	}

	log.Printf("🧹 [CACHE FLUSH] All keys deleted | Duration: %v", duration)
	return nil
}

func (r *RedisCache) GetAllKeys(ctx context.Context) ([]string, error) {
	keys, err := r.client.Keys(ctx, "*").Result()
	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE GET KEYS ERROR] Error: %v", err)
		return nil, err
	}
	return keys, nil
}

func (r *RedisCache) GetStats(ctx context.Context) CacheStats {
	hits := atomic.LoadUint64(&r.hits)
	misses := atomic.LoadUint64(&r.misses)
	sets := atomic.LoadUint64(&r.sets)
	deletes := atomic.LoadUint64(&r.deletes)
	errors := atomic.LoadUint64(&r.errors)

	total := hits + misses
	hitRate := 0.0
	if total > 0 {
		hitRate = float64(hits) / float64(total) * 100
	}

	// Get total keys from Redis
	keys, err := r.client.Keys(ctx, "*").Result()
	totalKeys := int64(0)
	if err == nil {
		totalKeys = int64(len(keys))
	}

	// Check connection
	connected := false
	if err := r.client.Ping(ctx).Err(); err == nil {
		connected = true
	}

	return CacheStats{
		Hits:      hits,
		Misses:    misses,
		Sets:      sets,
		Deletes:   deletes,
		Errors:    errors,
		HitRate:   hitRate,
		TotalKeys: totalKeys,
		RedisAddr: r.addr,
		Connected: connected,
	}
}

func (r *RedisCache) PrintStats(ctx context.Context) {
	stats := r.GetStats(ctx)
	log.Println("============================================================")
	log.Println("📊 PAYMENT SERVICE CACHE STATISTICS")
	log.Println("============================================================")
	log.Printf("✅ Cache Hits: %d", stats.Hits)
	log.Printf("❌ Cache Misses: %d", stats.Misses)
	log.Printf("💾 Cache Sets: %d", stats.Sets)
	log.Printf("🗑️  Cache Deletes: %d", stats.Deletes)
	log.Printf("⚠️  Cache Errors: %d", stats.Errors)
	log.Printf("📈 Hit Rate: %.2f%%", stats.HitRate)
	log.Printf("🔑 Total Keys: %d", stats.TotalKeys)
	log.Printf("🔌 Connected: %v", stats.Connected)
	log.Printf("📍 Redis Address: %s", stats.RedisAddr)
	log.Println("============================================================")
}

func (r *RedisCache) Close() error {
	return r.client.Close()
}

