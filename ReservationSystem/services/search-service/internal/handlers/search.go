package handlers

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

var mongoClient *mongo.Client
var mongoDatabase string

type Hotel struct {
	ID             string   `json:"_id" bson:"_id"`
	Name           string   `json:"name" bson:"name"`
	Location       string   `json:"location" bson:"location"`
	City           string   `json:"city" bson:"city"`
	Country        string   `json:"country" bson:"country"`
	Address        string   `json:"address" bson:"address"`
	Rating         float64  `json:"rating" bson:"rating"`
	PricePerNight  float64  `json:"price_per_night" bson:"price_per_night"`
	Description    string   `json:"description" bson:"description"`
	Amenities      []string `json:"amenities" bson:"amenities"`
	Images         []string `json:"images" bson:"images"`
	TotalRooms     int      `json:"total_rooms" bson:"total_rooms"`
	AvailableRooms int      `json:"available_rooms" bson:"available_rooms"`
}

type Room struct {
	ID            int     `json:"id"`
	HotelID       int     `json:"hotel_id"`
	Type          string  `json:"type"`
	Capacity      int     `json:"capacity"`
	PricePerNight float64 `json:"price_per_night"`
	Available     bool    `json:"available"`
}

func SetMongoClient(client *mongo.Client) {
	mongoClient = client
	// Get database name from environment variable, default to "hotel_db" for backward compatibility
	mongoDatabase = os.Getenv("MONGO_DATABASE")
	if mongoDatabase == "" {
		mongoDatabase = "hotel_db"
	}
	log.Printf("Using MongoDB database: %s", mongoDatabase)
}

func SearchHotels(c *gin.Context) {
	city := c.Query("city")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	filter := bson.M{}
	if city != "" {
		filter["city"] = bson.M{"$regex": city, "$options": "i"}
	}

	cursor, err := collection.Find(ctx, filter)
	if err != nil {
		log.Printf("Error fetching hotels: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch hotels"})
		return
	}
	defer cursor.Close(ctx)

	var hotels []Hotel
	if err = cursor.All(ctx, &hotels); err != nil {
		log.Printf("Error decoding hotels: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to decode hotels"})
		return
	}

	// Ensure we return an empty array instead of null
	if hotels == nil {
		hotels = []Hotel{}
	}

	c.JSON(http.StatusOK, hotels)
}

func GetHotelDetails(c *gin.Context) {
	id := c.Param("id")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	var hotel Hotel
	err := collection.FindOne(ctx, bson.M{"_id": id}).Decode(&hotel)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"error": "Hotel not found"})
			return
		}
		log.Printf("Error fetching hotel: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch hotel"})
		return
	}

	c.JSON(http.StatusOK, hotel)
}

func GetAvailableRooms(c *gin.Context) {
	hotelID := c.Param("id")
	checkIn := c.Query("checkIn")
	checkOut := c.Query("checkOut")

	// TODO: Check availability from inventory service
	// For now, return mock data

	rooms := []Room{
		{
			ID:            1,
			HotelID:       1,
			Type:          "Standard",
			Capacity:      2,
			PricePerNight: 200.00,
			Available:     true,
		},
		{
			ID:            2,
			HotelID:       1,
			Type:          "Deluxe",
			Capacity:      4,
			PricePerNight: 350.00,
			Available:     true,
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"hotel_id":  hotelID,
		"check_in":  checkIn,
		"check_out": checkOut,
		"rooms":     rooms,
	})
}
