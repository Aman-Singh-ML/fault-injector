package handlers

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// GetCacheStats returns cache statistics
func GetCacheStats(c *gin.Context) {
	if redisCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Redis cache not initialized",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	stats, err := redisCache.GetStats(ctx)
	if err != nil {
		log.Printf("❌ Failed to get cache stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get cache statistics",
		})
		return
	}

	log.Printf("📊 Cache stats requested - Hit Rate: %.2f%%, Total Keys: %d", stats.HitRate, stats.TotalKeys)
	c.JSON(http.StatusOK, stats)
}

// GetCacheKeys returns all cache keys matching a pattern
func GetCacheKeys(c *gin.Context) {
	if redisCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Redis cache not initialized",
		})
		return
	}

	pattern := c.Query("pattern")
	if pattern == "" {
		pattern = "*"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	keys, err := redisCache.GetAllKeys(ctx, pattern)
	if err != nil {
		log.Printf("❌ Failed to get cache keys: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get cache keys",
		})
		return
	}

	log.Printf("🔑 Retrieved %d cache keys with pattern: %s", len(keys), pattern)
	c.JSON(http.StatusOK, gin.H{
		"pattern": pattern,
		"count":   len(keys),
		"keys":    keys,
	})
}

// FlushCache clears all cache entries
func FlushCache(c *gin.Context) {
	if redisCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Redis cache not initialized",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := redisCache.FlushAll(ctx)
	if err != nil {
		log.Printf("❌ Failed to flush cache: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to flush cache",
		})
		return
	}

	log.Printf("🗑️  Cache flushed successfully")
	c.JSON(http.StatusOK, gin.H{
		"message": "Cache flushed successfully",
	})
}

// DeleteCacheKey deletes a specific cache key
func DeleteCacheKey(c *gin.Context) {
	if redisCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Redis cache not initialized",
		})
		return
	}

	key := c.Param("key")
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Cache key is required",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := redisCache.Delete(ctx, key)
	if err != nil {
		log.Printf("❌ Failed to delete cache key %s: %v", key, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to delete cache key",
		})
		return
	}

	log.Printf("🗑️  Deleted cache key: %s", key)
	c.JSON(http.StatusOK, gin.H{
		"message": "Cache key deleted successfully",
		"key":     key,
	})
}

// PrintCacheStats logs cache statistics to console
func PrintCacheStats(c *gin.Context) {
	if redisCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Redis cache not initialized",
		})
		return
	}

	redisCache.PrintStats()
	c.JSON(http.StatusOK, gin.H{
		"message": "Cache stats printed to console",
	})
}

