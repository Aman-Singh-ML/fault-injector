package main

import (
	"log"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/hotel/payment-service/internal/handlers"
)

func main() {
	gin.SetMode(gin.ReleaseMode)

	router := gin.Default()

	// CORS middleware
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

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
