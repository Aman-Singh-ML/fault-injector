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
	errors uint64
	addr   string
}

type CacheStats struct {
	Hits      uint64  `json:"hits"`
	Misses    uint64  `json:"misses"`
	Sets      uint64  `json:"sets"`
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

	duration := time.Since(startTime)
	atomic.AddUint64(&r.sets, 1)
	log.Printf("💾 [CACHE SET] Key: %s | TTL: %v | Size: %d bytes | Duration: %v",
		key, expiration, len(data), duration)
	return nil
}

func (r *RedisCache) Delete(ctx context.Context, key string) error {
	startTime := time.Now()
	err := r.client.Del(ctx, key).Err()
	duration := time.Since(startTime)

	if err != nil {
		atomic.AddUint64(&r.errors, 1)
		log.Printf("❌ [CACHE DELETE ERROR] Key: %s | Error: %v | Duration: %v", key, err, duration)
		return err
	}

	log.Printf("🗑️  [CACHE DELETE] Key: %s | Duration: %v", key, duration)
	return nil
}

func (r *RedisCache) GetStats(ctx context.Context) (*CacheStats, error) {
	hits := atomic.LoadUint64(&r.hits)
	misses := atomic.LoadUint64(&r.misses)
	sets := atomic.LoadUint64(&r.sets)
	errors := atomic.LoadUint64(&r.errors)

	total := hits + misses
	hitRate := 0.0
	if total > 0 {
		hitRate = float64(hits) / float64(total) * 100
	}

	// Get total keys from Redis
	totalKeys, err := r.client.DBSize(ctx).Result()
	if err != nil {
		log.Printf("⚠️  Failed to get Redis DB size: %v", err)
		totalKeys = -1
	}

	// Check connection
	connected := true
	if err := r.client.Ping(ctx).Err(); err != nil {
		connected = false
	}

	return &CacheStats{
		Hits:      hits,
		Misses:    misses,
		Sets:      sets,
		Errors:    errors,
		HitRate:   hitRate,
		TotalKeys: totalKeys,
		RedisAddr: r.addr,
		Connected: connected,
	}, nil
}

func (r *RedisCache) GetAllKeys(ctx context.Context, pattern string) ([]string, error) {
	if pattern == "" {
		pattern = "*"
	}

	keys, err := r.client.Keys(ctx, pattern).Result()
	if err != nil {
		log.Printf("❌ Failed to get keys with pattern %s: %v", pattern, err)
		return nil, err
	}

	log.Printf("🔑 Found %d keys matching pattern: %s", len(keys), pattern)
	return keys, nil
}

func (r *RedisCache) FlushAll(ctx context.Context) error {
	err := r.client.FlushDB(ctx).Err()
	if err != nil {
		log.Printf("❌ Failed to flush cache: %v", err)
		return err
	}

	// Reset stats
	atomic.StoreUint64(&r.hits, 0)
	atomic.StoreUint64(&r.misses, 0)
	atomic.StoreUint64(&r.sets, 0)
	atomic.StoreUint64(&r.errors, 0)

	log.Printf("🗑️  Cache flushed successfully")
	return nil
}

func (r *RedisCache) GetClient() *redis.Client {
	return r.client
}

func (r *RedisCache) PrintStats() {
	hits := atomic.LoadUint64(&r.hits)
	misses := atomic.LoadUint64(&r.misses)
	sets := atomic.LoadUint64(&r.sets)
	errors := atomic.LoadUint64(&r.errors)

	total := hits + misses
	hitRate := 0.0
	if total > 0 {
		hitRate = float64(hits) / float64(total) * 100
	}

	log.Printf("📊 [CACHE STATS] Hits: %d | Misses: %d | Sets: %d | Errors: %d | Hit Rate: %.2f%%",
		hits, misses, sets, errors, hitRate)
}

func (r *RedisCache) Close() error {
	r.PrintStats()
	log.Printf("🔌 Closing Redis connection to %s", r.addr)
	return r.client.Close()
}
