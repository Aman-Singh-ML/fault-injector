package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/hotel/payment-service/internal/handlers"
	"github.com/hotel/payment-service/internal/tracing"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/hotel/payment-service/internal/cache"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
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
	cleanup := tracing.InitTracing("payment-service")
	defer cleanup()

	// Initialize Redis cache for payment service (port 6383)
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6383"
	}
	redisClient := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	// Test Redis connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Printf("⚠️  Warning: Could not connect to Redis at %s: %v", redisAddr, err)
	} else {
		log.Printf("✅ Connected to Redis at %s", redisAddr)
	}

	// Set Redis client in handlers
	handlers.SetRedisClient(redisClient)


	// Initialize cache
	paymentCache := cache.NewRedisCache(redisAddr)
	handlers.SetCache(paymentCache)
	log.Println("✅ Payment cache initialized")

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sigChan
		log.Println("🛑 Shutting down payment service...")
		paymentCache.PrintStats(context.Background())
		paymentCache.Close()
		os.Exit(0)
	}()

	gin.SetMode(gin.ReleaseMode)

	router := gin.Default()

	// Add Prometheus middleware
	router.Use(prometheusMiddleware())

	// CORS middleware
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

	// Metrics endpoint
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "payment-service",
		})
	})

	// Payment routes
	router.POST("/payment/initiate", handlers.InitiatePayment)
	router.POST("/payment/verify-otp", handlers.VerifyOTP)
	router.GET("/payment/payments/:id", handlers.GetPaymentStatus)
	router.GET("/payment/bookings/:bookingId", handlers.GetPaymentByBooking)

	// Admin routes
	router.GET("/admin/payments", handlers.GetAllPayments)
	router.GET("/admin/payments/count", handlers.GetPaymentsCount)
	router.GET("/admin/payments/stats", handlers.GetPaymentsStats)
	router.GET("/admin/payments/recent", handlers.GetRecentPayments)
	router.GET("/admin/payments/user/:userId", handlers.GetPaymentsByUser)

	// Cache management routes
	router.GET("/admin/cache/stats", handlers.GetCacheStats)
	router.GET("/admin/cache/keys", handlers.GetCacheKeys)
	router.POST("/admin/cache/flush", handlers.FlushCache)
	router.DELETE("/admin/cache/keys/:key", handlers.DeleteCacheKey)
	router.GET("/admin/cache/print-stats", handlers.PrintCacheStats)
	
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("💳 Payment Service starting on port %s", port)
	log.Printf("📡 Health check: http://localhost:%s/health", port)
	log.Printf("💰 Initiate payment: POST http://localhost:%s/payment/initiate", port)
	log.Printf("🔐 Verify OTP: POST http://localhost:%s/payment/verify-otp", port)

	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
