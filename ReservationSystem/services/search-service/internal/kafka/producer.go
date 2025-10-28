package kafka

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/segmentio/kafka-go"
)

type BookingRequest struct {
	UserID       string  `json:"userId"`
	HotelID      string  `json:"hotelId"`
	HotelName    string  `json:"hotelName"`
	CheckInDate  string  `json:"checkInDate"`
	CheckOutDate string  `json:"checkOutDate"`
	Rooms        int     `json:"rooms"`
	Adults       int     `json:"adults"`
	Children     int     `json:"children"`
	TotalPrice   float64 `json:"totalPrice"`
}

var writer *kafka.Writer

// InitProducer initializes the Kafka producer for booking requests
// Uses kafka-booking instance (port 9094) for dedicated booking topic
func InitProducer() error {
	kafkaServers := os.Getenv("KAFKA_BOOKING_SERVERS")
	if kafkaServers == "" {
		kafkaServers = "localhost:9094" // Use kafka-booking instance
	}

	brokers := strings.Split(kafkaServers, ",")
	log.Printf("Initializing Kafka producer with brokers: %v", brokers)

	writer = kafka.NewWriter(kafka.WriterConfig{
		Brokers:  brokers,
		Topic:    "booking-requests",
		Balancer: &kafka.LeastBytes{},
	})

	log.Println("✅ Kafka producer initialized for booking-requests topic on kafka-booking instance")
	return nil
}

// PublishBookingRequest publishes a booking request to Kafka
func PublishBookingRequest(booking BookingRequest) error {
	if writer == nil {
		return fmt.Errorf("Kafka producer not initialized")
	}

	data, err := json.Marshal(booking)
	if err != nil {
		return fmt.Errorf("failed to marshal booking: %w", err)
	}

	msg := kafka.Message{
		Key:   []byte(booking.UserID),
		Value: data,
	}

	ctx := context.Background()
	err = writer.WriteMessages(ctx, msg)
	if err != nil {
		log.Printf("❌ Failed to publish booking request: %v", err)
		return fmt.Errorf("failed to publish message: %w", err)
	}

	log.Printf("📨 Published booking request to Kafka: User=%s, Hotel=%s", booking.UserID, booking.HotelID)
	return nil
}

// CloseProducer closes the Kafka producer
func CloseProducer() error {
	if writer != nil {
		return writer.Close()
	}
	return nil
}
