package handlers

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
)

// GetCacheStats returns cache statistics
func GetCacheStats(c *gin.Context) {
	if paymentCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Cache not available"})
		return
	}

	ctx := context.Background()
	stats := paymentCache.GetStats(ctx)
	c.JSON(http.StatusOK, stats)
}

// GetCacheKeys returns all cache keys
func GetCacheKeys(c *gin.Context) {
	if paymentCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Cache not available"})
		return
	}

	ctx := context.Background()
	keys, err := paymentCache.GetAllKeys(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get cache keys"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"keys":  keys,
		"count": len(keys),
	})
}

// FlushCache clears all cache
func FlushCache(c *gin.Context) {
	if paymentCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Cache not available"})
		return
	}

	ctx := context.Background()
	if err := paymentCache.FlushAll(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to flush cache"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cache flushed successfully",
	})
}

// DeleteCacheKey deletes a specific cache key
func DeleteCacheKey(c *gin.Context) {
	if paymentCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Cache not available"})
		return
	}

	key := c.Param("key")
	ctx := context.Background()
	if err := paymentCache.Delete(ctx, key); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete cache key"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cache key deleted successfully",
		"key":     key,
	})
}

// PrintCacheStats prints cache statistics to console
func PrintCacheStats(c *gin.Context) {
	if paymentCache == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Cache not available"})
		return
	}

	ctx := context.Background()
	paymentCache.PrintStats(ctx)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cache stats printed to console",
	})
}

