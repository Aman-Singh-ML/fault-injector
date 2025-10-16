package models

import "time"

type Hotel struct {
	ID          string    `json:"id" bson:"_id,omitempty"`
	Name        string    `json:"name" bson:"name"`
	Location    string    `json:"location" bson:"location"`
	Address     string    `json:"address" bson:"address"`
	Rating      float64   `json:"rating" bson:"rating"`
	Description string    `json:"description" bson:"description"`
	Amenities   []string  `json:"amenities" bson:"amenities"`
	Images      []string  `json:"images" bson:"images"`
	CreatedAt   time.Time `json:"created_at" bson:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" bson:"updated_at"`
}

type SearchQuery struct {
	Location  string    `json:"location"`
	CheckIn   time.Time `json:"check_in"`
	CheckOut  time.Time `json:"check_out"`
	Guests    int       `json:"guests"`
	Rooms     int       `json:"rooms"`
	MinPrice  float64   `json:"min_price"`
	MaxPrice  float64   `json:"max_price"`
	MinRating float64   `json:"min_rating"`
}

