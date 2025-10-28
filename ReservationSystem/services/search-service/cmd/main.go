package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hotel/search-service/internal/cache"
	"github.com/hotel/search-service/internal/handlers"
	"github.com/hotel/search-service/internal/kafka"
	"github.com/hotel/search-service/internal/tracing"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request latency in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)
)

func prometheusMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start).Seconds()
		status := c.Writer.Status()

		httpRequestsTotal.WithLabelValues(c.Request.Method, c.FullPath(), string(rune(status))).Inc()
		httpRequestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration)
	}
}

func main() {
	// Initialize tracing
	cleanup := tracing.InitTracing("search-service")
	defer cleanup()
	// Connect to MongoDB
	mongoURI := os.Getenv("MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://admin:admin@localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal("Failed to connect to MongoDB:", err)
	}
	defer client.Disconnect(context.Background())

	// Ping MongoDB
	if err := client.Ping(ctx, nil); err != nil {
		log.Fatal("Failed to ping MongoDB:", err)
	}
	log.Println("✅ Connected to MongoDB")

	// Set MongoDB client in handlers
	handlers.SetMongoClient(client)

	// Initialize Redis cache for search service (port 6381)
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6381"
	}
	redisCache := cache.NewRedisCache(redisAddr)
	handlers.SetRedisCache(redisCache)
	log.Printf("✅ Connected to Redis at %s", redisAddr)

	// Initialize Kafka producer
	if err := kafka.InitProducer(); err != nil {
		log.Printf("⚠️  Warning: Failed to initialize Kafka producer: %v", err)
		// Don't fail startup if Kafka is not available
	}
	defer kafka.CloseProducer()

	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	// Create router
	router := gin.Default()

	// Add Prometheus middleware
	router.Use(prometheusMiddleware())

	// Metrics endpoint
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "search-service",
		})
	})

	// Search routes
	router.GET("/search", handlers.SearchHotels)
	router.GET("/search/hotels", handlers.SearchHotels)        // Frontend expects this route
	router.GET("/search/hotels/:id", handlers.GetHotelDetails) // Hotel details
	router.GET("/hotels/:id", handlers.GetHotelDetails)
	router.GET("/hotels/:id/rooms", handlers.GetAvailableRooms)

	// Booking routes (via Kafka)
	router.POST("/search/start-booking", handlers.StartBooking) // Initial booking request
	router.POST("/search/book", handlers.CreateBooking)         // Confirm and publish to Kafka
	router.POST("/book", handlers.CreateBooking)

	// Admin routes
	router.GET("/admin/hotels", handlers.GetAllHotelsAdmin)
	router.GET("/admin/hotels/count", handlers.GetHotelsCount)
	router.GET("/admin/hotels/stats", handlers.GetHotelsStats)
	router.GET("/admin/hotels/by-city", handlers.GetHotelsByCity)
	router.GET("/admin/hotels/top-rated", handlers.GetTopRatedHotels)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Search service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
