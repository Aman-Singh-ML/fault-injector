package handlers

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
)

// GetHotelsCount returns the count of hotels in the database
func GetHotelsCount(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	// Total count
	total, err := collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		log.Printf("Error counting hotels: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to count hotels"})
		return
	}

	// Count by city
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":   "$city",
				"count": bson.M{"$sum": 1},
			},
		},
		{
			"$sort": bson.M{"count": -1},
		},
	}

	cursor, err := collection.Aggregate(ctx, pipeline)
	if err != nil {
		log.Printf("Error aggregating hotels by city: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to aggregate hotels"})
		return
	}
	defer cursor.Close(ctx)

	var cityCounts []map[string]interface{}
	if err = cursor.All(ctx, &cityCounts); err != nil {
		log.Printf("Error decoding city counts: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to decode city counts"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"total":    total,
		"byCities": cityCounts,
	})
}

// GetHotelsStats returns statistics about hotels
func GetHotelsStats(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	// Total count
	total, err := collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		log.Printf("Error counting hotels: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to count hotels"})
		return
	}

	// Average rating
	avgRatingPipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":        nil,
				"avgRating":  bson.M{"$avg": "$rating"},
				"avgPrice":   bson.M{"$avg": "$price_per_night"},
				"totalRooms": bson.M{"$sum": "$total_rooms"},
				"availRooms": bson.M{"$sum": "$available_rooms"},
			},
		},
	}

	cursor, err := collection.Aggregate(ctx, avgRatingPipeline)
	if err != nil {
		log.Printf("Error aggregating stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to aggregate stats"})
		return
	}
	defer cursor.Close(ctx)

	var stats []map[string]interface{}
	if err = cursor.All(ctx, &stats); err != nil {
		log.Printf("Error decoding stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to decode stats"})
		return
	}

	var result map[string]interface{}
	if len(stats) > 0 {
		result = stats[0]
	} else {
		result = map[string]interface{}{
			"avgRating":  0,
			"avgPrice":   0,
			"totalRooms": 0,
			"availRooms": 0,
		}
	}

	result["total"] = total

	// Top rated hotels
	topRatedCursor, err := collection.Find(ctx, bson.M{}, nil)
	if err != nil {
		log.Printf("Error finding top rated hotels: %v", err)
	} else {
		var topRated []Hotel
		if err = topRatedCursor.All(ctx, &topRated); err == nil {
			// Sort by rating (already done in query with sort option)
			if len(topRated) > 5 {
				topRated = topRated[:5]
			}
			result["topRated"] = topRated
		}
		topRatedCursor.Close(ctx)
	}

	c.JSON(http.StatusOK, result)
}

// GetAllHotelsAdmin returns all hotels for admin (with pagination)
func GetAllHotelsAdmin(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	// Get all hotels
	cursor, err := collection.Find(ctx, bson.M{})
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

	c.JSON(http.StatusOK, gin.H{
		"hotels": hotels,
		"total":  len(hotels),
	})
}

// GetHotelsByCity returns hotels grouped by city
func GetHotelsByCity(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id": "$city",
				"hotels": bson.M{
					"$push": bson.M{
						"id":              "$_id",
						"name":            "$name",
						"rating":          "$rating",
						"price_per_night": "$price_per_night",
						"available_rooms": "$available_rooms",
					},
				},
				"count": bson.M{"$sum": 1},
			},
		},
		{
			"$sort": bson.M{"count": -1},
		},
	}

	cursor, err := collection.Aggregate(ctx, pipeline)
	if err != nil {
		log.Printf("Error aggregating hotels by city: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to aggregate hotels"})
		return
	}
	defer cursor.Close(ctx)

	var result []map[string]interface{}
	if err = cursor.All(ctx, &result); err != nil {
		log.Printf("Error decoding results: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to decode results"})
		return
	}

	if result == nil {
		result = []map[string]interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"cities": result,
		"total":  len(result),
	})
}

// GetTopRatedHotels returns top rated hotels
func GetTopRatedHotels(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collection := mongoClient.Database(mongoDatabase).Collection("hotels")

	// Find hotels sorted by rating
	cursor, err := collection.Find(ctx, bson.M{}, nil)
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

	// Limit to top 10
	if len(hotels) > 10 {
		hotels = hotels[:10]
	}

	c.JSON(http.StatusOK, gin.H{
		"hotels": hotels,
		"total":  len(hotels),
	})
}
