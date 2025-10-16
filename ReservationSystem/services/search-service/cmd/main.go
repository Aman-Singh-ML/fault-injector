package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hotel/search-service/internal/handlers"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
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

	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	// Create router
	router := gin.Default()

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
