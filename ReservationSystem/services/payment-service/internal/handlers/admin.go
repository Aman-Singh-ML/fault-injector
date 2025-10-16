package handlers

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// GetAllPayments returns all payments (admin only)
func GetAllPayments(c *gin.Context) {
	status := c.Query("status")
	limit := c.DefaultQuery("limit", "100")
	offset := c.DefaultQuery("offset", "0")

	query := `
		SELECT id, booking_id, user_id, amount, status, transaction_id, created_at, updated_at
		FROM payments
	`
	args := []interface{}{}

	if status != "" {
		query += " WHERE status = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3"
		args = append(args, status, limit, offset)
	} else {
		query += " ORDER BY created_at DESC LIMIT $1 OFFSET $2"
		args = append(args, limit, offset)
	}

	rows, err := db.Query(query, args...)
	if err != nil {
		log.Printf("Error fetching payments: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch payments"})
		return
	}
	defer rows.Close()

	var payments []map[string]interface{}
	for rows.Next() {
		var id, bookingID, userID int
		var amount float64
		var status, transactionID sql.NullString
		var createdAt, updatedAt string

		err := rows.Scan(&id, &bookingID, &userID, &amount, &status, &transactionID, &createdAt, &updatedAt)
		if err != nil {
			log.Printf("Error scanning payment: %v", err)
			continue
		}

		payment := map[string]interface{}{
			"id":        id,
			"bookingId": bookingID,
			"userId":    userID,
			"amount":    amount,
			"status":    status.String,
			"createdAt": createdAt,
			"updatedAt": updatedAt,
		}

		if transactionID.Valid {
			payment["transactionId"] = transactionID.String
		}

		payments = append(payments, payment)
	}

	if payments == nil {
		payments = []map[string]interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"payments": payments,
		"total":    len(payments),
	})
}

// GetPaymentsCount returns payment counts by status
func GetPaymentsCount(c *gin.Context) {
	// Total count
	var total int
	err := db.QueryRow("SELECT COUNT(*) FROM payments").Scan(&total)
	if err != nil {
		log.Printf("Error counting payments: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to count payments"})
		return
	}

	// Count by status
	var pending, success, failed int
	db.QueryRow("SELECT COUNT(*) FROM payments WHERE status = 'PENDING'").Scan(&pending)
	db.QueryRow("SELECT COUNT(*) FROM payments WHERE status = 'SUCCESS'").Scan(&success)
	db.QueryRow("SELECT COUNT(*) FROM payments WHERE status = 'FAILED'").Scan(&failed)

	c.JSON(http.StatusOK, gin.H{
		"total": total,
		"byStatus": gin.H{
			"pending": pending,
			"success": success,
			"failed":  failed,
		},
	})
}

// GetPaymentsStats returns payment statistics
func GetPaymentsStats(c *gin.Context) {
	// Total count
	var total int
	err := db.QueryRow("SELECT COUNT(*) FROM payments").Scan(&total)
	if err != nil {
		log.Printf("Error counting payments: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to count payments"})
		return
	}

	// Total revenue (successful payments)
	var totalRevenue sql.NullFloat64
	err = db.QueryRow("SELECT SUM(amount) FROM payments WHERE status = 'SUCCESS'").Scan(&totalRevenue)
	if err != nil {
		log.Printf("Error calculating revenue: %v", err)
	}

	revenue := 0.0
	if totalRevenue.Valid {
		revenue = totalRevenue.Float64
	}

	// Average payment amount
	var avgAmount sql.NullFloat64
	err = db.QueryRow("SELECT AVG(amount) FROM payments WHERE status = 'SUCCESS'").Scan(&avgAmount)
	if err != nil {
		log.Printf("Error calculating average: %v", err)
	}

	avg := 0.0
	if avgAmount.Valid {
		avg = avgAmount.Float64
	}

	// Count by status
	var pending, success, failed int
	db.QueryRow("SELECT COUNT(*) FROM payments WHERE status = 'PENDING'").Scan(&pending)
	db.QueryRow("SELECT COUNT(*) FROM payments WHERE status = 'SUCCESS'").Scan(&success)
	db.QueryRow("SELECT COUNT(*) FROM payments WHERE status = 'FAILED'").Scan(&failed)

	// Success rate
	successRate := 0.0
	if total > 0 {
		successRate = (float64(success) / float64(total)) * 100
	}

	c.JSON(http.StatusOK, gin.H{
		"total":          total,
		"totalRevenue":   revenue,
		"averageAmount":  avg,
		"successRate":    successRate,
		"byStatus": gin.H{
			"pending": pending,
			"success": success,
			"failed":  failed,
		},
	})
}

// GetRecentPayments returns recent payments
func GetRecentPayments(c *gin.Context) {
	limit := c.DefaultQuery("limit", "10")

	rows, err := db.Query(`
		SELECT id, booking_id, user_id, amount, status, transaction_id, created_at, updated_at
		FROM payments
		ORDER BY created_at DESC
		LIMIT $1
	`, limit)
	if err != nil {
		log.Printf("Error fetching recent payments: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch payments"})
		return
	}
	defer rows.Close()

	var payments []map[string]interface{}
	for rows.Next() {
		var id, bookingID, userID int
		var amount float64
		var status, transactionID sql.NullString
		var createdAt, updatedAt string

		err := rows.Scan(&id, &bookingID, &userID, &amount, &status, &transactionID, &createdAt, &updatedAt)
		if err != nil {
			log.Printf("Error scanning payment: %v", err)
			continue
		}

		payment := map[string]interface{}{
			"id":        id,
			"bookingId": bookingID,
			"userId":    userID,
			"amount":    amount,
			"status":    status.String,
			"createdAt": createdAt,
			"updatedAt": updatedAt,
		}

		if transactionID.Valid {
			payment["transactionId"] = transactionID.String
		}

		payments = append(payments, payment)
	}

	if payments == nil {
		payments = []map[string]interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"payments": payments,
		"count":    len(payments),
	})
}

// GetPaymentsByUser returns payments for a specific user
func GetPaymentsByUser(c *gin.Context) {
	userID := c.Param("userId")

	rows, err := db.Query(`
		SELECT id, booking_id, user_id, amount, status, transaction_id, created_at, updated_at
		FROM payments
		WHERE user_id = $1
		ORDER BY created_at DESC
	`, userID)
	if err != nil {
		log.Printf("Error fetching user payments: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch payments"})
		return
	}
	defer rows.Close()

	var payments []map[string]interface{}
	for rows.Next() {
		var id, bookingID, userID int
		var amount float64
		var status, transactionID sql.NullString
		var createdAt, updatedAt string

		err := rows.Scan(&id, &bookingID, &userID, &amount, &status, &transactionID, &createdAt, &updatedAt)
		if err != nil {
			log.Printf("Error scanning payment: %v", err)
			continue
		}

		payment := map[string]interface{}{
			"id":        id,
			"bookingId": bookingID,
			"userId":    userID,
			"amount":    amount,
			"status":    status.String,
			"createdAt": createdAt,
			"updatedAt": updatedAt,
		}

		if transactionID.Valid {
			payment["transactionId"] = transactionID.String
		}

		payments = append(payments, payment)
	}

	if payments == nil {
		payments = []map[string]interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"payments": payments,
		"total":    len(payments),
	})
}

