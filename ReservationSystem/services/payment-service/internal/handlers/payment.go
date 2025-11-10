package handlers

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/hotel/payment-service/internal/cache"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	_ "github.com/lib/pq"
	amqp "github.com/rabbitmq/amqp091-go"
)

var redisClient *redis.Client
var paymentCache *cache.RedisCache

// SetRedisClient sets the Redis client for payment handlers
func SetRedisClient(client *redis.Client) {
	redisClient = client
}

// SetCache sets the cache for payment handlers
func SetCache(c *cache.RedisCache) {
	paymentCache = c
}

// FlexibleString can unmarshal both string and number
type FlexibleString string

func (fs *FlexibleString) UnmarshalJSON(data []byte) error {
	// Try to unmarshal as string first
	var s string
	if err := json.Unmarshal(data, &s); err == nil {
		*fs = FlexibleString(s)
		return nil
	}

	// Try to unmarshal as number
	var n float64
	if err := json.Unmarshal(data, &n); err == nil {
		*fs = FlexibleString(fmt.Sprintf("%.0f", n))
		return nil
	}

	return fmt.Errorf("cannot unmarshal %s into FlexibleString", string(data))
}

type InitiatePaymentRequest struct {
	BookingID FlexibleString `json:"bookingId" binding:"required"`
	UserID    FlexibleString `json:"userId" binding:"required"`
	Amount    float64        `json:"amount" binding:"required"`
}

type VerifyOTPRequest struct {
	PaymentID FlexibleString `json:"paymentId" binding:"required"`
	OTP       string         `json:"otp" binding:"required"`
}

type Payment struct {
	ID            int       `json:"id"`
	BookingID     int       `json:"bookingId"`
	UserID        int       `json:"userId"`
	Amount        float64   `json:"amount"`
	Status        string    `json:"status"`
	OTP           string    `json:"otp,omitempty"`
	TransactionID string    `json:"transactionId,omitempty"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

var db *sql.DB
var rabbitConn *amqp.Connection
var rabbitChannel *amqp.Channel

func init() {
	// Initialize database
	var err error
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5434")
	dbUser := getEnv("DB_USER", "payment_user")
	dbPassword := getEnv("DB_PASSWORD", "payment_pass")
	dbName := getEnv("DB_NAME", "payment_db")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	db, err = sql.Open("postgres", connStr)
	if err != nil {
		panic(fmt.Sprintf("Failed to connect to database: %v", err))
	}

	// Create table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS payments (
			id SERIAL PRIMARY KEY,
			booking_id INTEGER NOT NULL,
			user_id INTEGER NOT NULL,
			amount DECIMAL(10, 2) NOT NULL,
			status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
			otp VARCHAR(6),
			transaction_id VARCHAR(255),
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
		CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
		CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
	`)
	if err != nil {
		panic(fmt.Sprintf("Failed to create table: %v", err))
	}

	// Initialize RabbitMQ
	rabbitURL := getEnv("RABBITMQ_URL", "amqp://admin:admin@localhost:5672/")
	rabbitConn, err = amqp.Dial(rabbitURL)
	if err != nil {
		fmt.Printf("⚠️  Failed to connect to RabbitMQ: %v\n", err)
	} else {
		rabbitChannel, err = rabbitConn.Channel()
		if err != nil {
			fmt.Printf("⚠️  Failed to open RabbitMQ channel: %v\n", err)
		} else {
			// Declare exchange
			err = rabbitChannel.ExchangeDeclare(
				"payment_events", // name
				"topic",          // type
				true,             // durable
				false,            // auto-deleted
				false,            // internal
				false,            // no-wait
				nil,              // arguments
			)
			if err != nil {
				fmt.Printf("⚠️  Failed to declare exchange: %v\n", err)
			}
		}
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// InitiatePayment creates a payment and generates OTP
func InitiatePayment(c *gin.Context) {
	var req InitiatePaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Generate 6-digit OTP
	otp := fmt.Sprintf("%06d", rand.Intn(1000000))

	// Convert userId string to int
	userID, err := strconv.Atoi(string(req.UserID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid userId format"})
		return
	}

	// Convert bookingId string to int
	bookingID, err := strconv.Atoi(string(req.BookingID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid bookingId format"})
		return
	}

	// Insert payment into database
	var paymentID int
	err = db.QueryRow(`
		INSERT INTO payments (booking_id, user_id, amount, currency, status, payment_method, otp, created_at, updated_at)
		VALUES ($1, $2, $3, 'USD', 'PENDING', 'OTP', $4, NOW(), NOW())
		RETURNING id
	`, bookingID, userID, req.Amount, otp).Scan(&paymentID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create payment"})
		return
	}

	fmt.Printf("💳 Payment initiated: ID=%d, OTP=%s\n", paymentID, otp)

	c.JSON(http.StatusCreated, gin.H{
		"paymentId": paymentID,
		"otp":       otp, // In production, send via SMS/Email
		"status":    "PENDING",
		"message":   "Please verify OTP to complete payment",
	})
}

// VerifyOTP verifies the OTP and completes payment
func VerifyOTP(c *gin.Context) {
	var req VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Convert paymentId to int
	paymentID, err := strconv.Atoi(string(req.PaymentID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid paymentId format"})
		return
	}

	// Fetch payment from database
	var payment Payment
	var storedOTP string
	var transactionID sql.NullString
	err = db.QueryRow(`
		SELECT id, booking_id, user_id, amount, status, otp, transaction_id, created_at, updated_at
		FROM payments
		WHERE id = $1
	`, paymentID).Scan(
		&payment.ID, &payment.BookingID, &payment.UserID, &payment.Amount,
		&payment.Status, &storedOTP, &transactionID, &payment.CreatedAt, &payment.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	} else if err != nil {
		fmt.Printf("❌ Database error: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Set transaction ID if valid
	if transactionID.Valid {
		payment.TransactionID = transactionID.String
	}

	// Check if already completed
	if payment.Status == "COMPLETED" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment already completed"})
		return
	}

	// Verify OTP
	if storedOTP != req.OTP {
		fmt.Printf("❌ OTP verification failed: Expected=%s, Got=%s\n", storedOTP, req.OTP)

		// Publish failure event to RabbitMQ
		publishPaymentEvent("payment.failed", map[string]interface{}{
			"paymentId": payment.ID,
			"bookingId": payment.BookingID,
			"userId":    payment.UserID,
			"reason":    "Invalid OTP",
			"timestamp": time.Now().Format(time.RFC3339),
		})

		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid OTP"})
		return
	}

	// Generate transaction ID
	txnID := fmt.Sprintf("TXN-%d-%d", time.Now().Unix(), payment.ID)

	// Update payment status
	_, err = db.Exec(`
		UPDATE payments
		SET status = 'COMPLETED', transaction_id = $1, updated_at = NOW()
		WHERE id = $2
	`, txnID, payment.ID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update payment"})
		return
	}

	payment.Status = "COMPLETED"
	payment.TransactionID = txnID
	payment.UpdatedAt = time.Now()

	fmt.Printf("✅ Payment completed: ID=%d, TXN=%s\n", payment.ID, txnID)

	// Invalidate cache
	if paymentCache != nil {
		ctx := context.Background()
		paymentKey := fmt.Sprintf("payment:%d", payment.ID)
		bookingKey := fmt.Sprintf("payment:booking:%d", payment.BookingID)
		if err := paymentCache.Delete(ctx, paymentKey, bookingKey); err != nil {
			fmt.Printf("⚠️  [VERIFY OTP] Failed to invalidate cache: %v\n", err)
		} else {
			fmt.Printf("✅ [VERIFY OTP] Invalidated cache for payment ID: %d and booking ID: %d\n", payment.ID, payment.BookingID)
		}
	}

	// Publish success event to RabbitMQ
	publishPaymentEvent("payment.success", map[string]interface{}{
		"paymentId":     payment.ID,
		"bookingId":     payment.BookingID,
		"userId":        payment.UserID,
		"amount":        payment.Amount,
		"transactionId": txnID,
		"timestamp":     time.Now().Format(time.RFC3339),
	})

	c.JSON(http.StatusOK, payment)
}

// GetPaymentStatus retrieves payment status
func GetPaymentStatus(c *gin.Context) {
	id := c.Param("id")
	ctx := context.Background()

	// Try cache first
	if paymentCache != nil {
		cacheKey := fmt.Sprintf("payment:%s", id)
		var cachedPayment Payment
		if err := paymentCache.Get(ctx, cacheKey, &cachedPayment); err == nil {
			fmt.Printf("✅ [PAYMENT STATUS] Cache hit for payment ID: %s\n", id)
			c.JSON(http.StatusOK, cachedPayment)
			return
		}
		fmt.Printf("⚠️  [PAYMENT STATUS] Cache miss for payment ID: %s\n", id)
	}

	var payment Payment
	var transactionID sql.NullString
	err := db.QueryRow(`
		SELECT id, booking_id, user_id, amount, status, transaction_id, created_at, updated_at
		FROM payments
		WHERE id = $1
	`, id).Scan(
		&payment.ID, &payment.BookingID, &payment.UserID, &payment.Amount,
		&payment.Status, &transactionID, &payment.CreatedAt, &payment.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	if transactionID.Valid {
		payment.TransactionID = transactionID.String
	}

	// Cache the result (1 hour TTL)
	if paymentCache != nil {
		cacheKey := fmt.Sprintf("payment:%s", id)
		if err := paymentCache.Set(ctx, cacheKey, payment, 1*time.Hour); err != nil {
			fmt.Printf("⚠️  [PAYMENT STATUS] Failed to cache payment: %v\n", err)
		} else {
			fmt.Printf("✅ [PAYMENT STATUS] Cached payment with key: %s\n", cacheKey)
		}
	}

	c.JSON(http.StatusOK, payment)
}

// GetPaymentByBooking retrieves payment by booking ID
func GetPaymentByBooking(c *gin.Context) {
	bookingID := c.Param("bookingId")
	ctx := context.Background()

	// Try cache first
	if paymentCache != nil {
		cacheKey := fmt.Sprintf("payment:booking:%s", bookingID)
		var cachedPayment Payment
		if err := paymentCache.Get(ctx, cacheKey, &cachedPayment); err == nil {
			fmt.Printf("✅ [PAYMENT BY BOOKING] Cache hit for booking ID: %s\n", bookingID)
			c.JSON(http.StatusOK, cachedPayment)
			return
		}
		fmt.Printf("⚠️  [PAYMENT BY BOOKING] Cache miss for booking ID: %s\n", bookingID)
	}

	var payment Payment
	var transactionID sql.NullString
	err := db.QueryRow(`
		SELECT id, booking_id, user_id, amount, status, transaction_id, created_at, updated_at
		FROM payments
		WHERE booking_id = $1
		ORDER BY created_at DESC
		LIMIT 1
	`, bookingID).Scan(
		&payment.ID, &payment.BookingID, &payment.UserID, &payment.Amount,
		&payment.Status, &transactionID, &payment.CreatedAt, &payment.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	if transactionID.Valid {
		payment.TransactionID = transactionID.String
	}

	// Cache the result (1 hour TTL)
	if paymentCache != nil {
		cacheKey := fmt.Sprintf("payment:booking:%s", bookingID)
		if err := paymentCache.Set(ctx, cacheKey, payment, 1*time.Hour); err != nil {
			fmt.Printf("⚠️  [PAYMENT BY BOOKING] Failed to cache payment: %v\n", err)
		} else {
			fmt.Printf("✅ [PAYMENT BY BOOKING] Cached payment with key: %s\n", cacheKey)
		}
	}

	c.JSON(http.StatusOK, payment)
}

// publishPaymentEvent publishes event to RabbitMQ
func publishPaymentEvent(eventType string, data map[string]interface{}) {
	if rabbitChannel == nil {
		fmt.Println("⚠️  RabbitMQ channel not available")
		return
	}

	data["eventType"] = eventType
	body, _ := json.Marshal(data)

	err := rabbitChannel.Publish(
		"payment_events", // exchange
		eventType,        // routing key
		false,            // mandatory
		false,            // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		},
	)

	if err != nil {
		fmt.Printf("⚠️  Failed to publish event: %v\n", err)
	} else {
		fmt.Printf("📨 Published %s event to RabbitMQ\n", eventType)
	}
}
