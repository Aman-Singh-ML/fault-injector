package models

import "time"

type Payment struct {
	ID            int       `json:"id"`
	BookingID     int       `json:"booking_id"`
	UserID        int       `json:"user_id"`
	Amount        float64   `json:"amount"`
	Currency      string    `json:"currency"`
	Status        string    `json:"status"`
	PaymentMethod string    `json:"payment_method"`
	TransactionID string    `json:"transaction_id"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

const (
	PaymentStatusPending   = "PENDING"
	PaymentStatusSuccess   = "SUCCESS"
	PaymentStatusFailed    = "FAILED"
	PaymentStatusRefunded  = "REFUNDED"
)

