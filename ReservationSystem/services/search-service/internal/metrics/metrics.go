package metrics

import (
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"strconv"
	"time"
)

var (
	// HTTP metrics
	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "search_service_http_request_duration_seconds",
			Help:    "Duration of HTTP requests in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint", "status_code"},
	)

	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "search_service_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status_code"},
	)

	// Database metrics
	mongoOperationDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "search_service_mongo_operation_duration_seconds",
			Help:    "Duration of MongoDB operations in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"operation", "collection"},
	)

	mongoOperationsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "search_service_mongo_operations_total",
			Help: "Total number of MongoDB operations",
		},
		[]string{"operation", "collection", "status"},
	)

	// Redis metrics
	redisOperationDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "search_service_redis_operation_duration_seconds",
			Help:    "Duration of Redis operations in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"operation"},
	)

	redisOperationsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "search_service_redis_operations_total",
			Help: "Total number of Redis operations",
		},
		[]string{"operation", "status"},
	)

	// Business metrics
	hotelSearchesTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "search_service_hotel_searches_total",
			Help: "Total number of hotel searches",
		},
		[]string{"city", "status"},
	)

	hotelSearchDuration = prometheus.NewHistogram(
		prometheus.HistogramOpts{
			Name:    "search_service_hotel_search_duration_seconds",
			Help:    "Duration of hotel search operations in seconds",
			Buckets: prometheus.DefBuckets,
		},
	)

	cacheHitsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "search_service_cache_hits_total",
			Help: "Total number of cache hits",
		},
		[]string{"cache_type"},
	)

	cacheMissesTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "search_service_cache_misses_total",
			Help: "Total number of cache misses",
		},
		[]string{"cache_type"},
	)
)

// InitMetrics initializes Prometheus metrics
func InitMetrics() {
	prometheus.MustRegister(
		httpRequestDuration,
		httpRequestsTotal,
		mongoOperationDuration,
		mongoOperationsTotal,
		redisOperationDuration,
		redisOperationsTotal,
		hotelSearchesTotal,
		hotelSearchDuration,
		cacheHitsTotal,
		cacheMissesTotal,
	)
}

// PrometheusMiddleware creates a Gin middleware for Prometheus metrics
func PrometheusMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start).Seconds()
		statusCode := strconv.Itoa(c.Writer.Status())

		httpRequestDuration.WithLabelValues(
			c.Request.Method,
			c.FullPath(),
			statusCode,
		).Observe(duration)

		httpRequestsTotal.WithLabelValues(
			c.Request.Method,
			c.FullPath(),
			statusCode,
		).Inc()
	}
}

// PrometheusHandler returns the Prometheus metrics handler
func PrometheusHandler() gin.HandlerFunc {
	h := promhttp.Handler()
	return func(c *gin.Context) {
		h.ServeHTTP(c.Writer, c.Request)
	}
}

// Business metric helpers
func RecordHotelSearch(city, status string, duration time.Duration) {
	hotelSearchesTotal.WithLabelValues(city, status).Inc()
	hotelSearchDuration.Observe(duration.Seconds())
}

func RecordCacheHit(cacheType string) {
	cacheHitsTotal.WithLabelValues(cacheType).Inc()
}

func RecordCacheMiss(cacheType string) {
	cacheMissesTotal.WithLabelValues(cacheType).Inc()
}

func RecordMongoOperation(operation, collection, status string, duration time.Duration) {
	mongoOperationDuration.WithLabelValues(operation, collection).Observe(duration.Seconds())
	mongoOperationsTotal.WithLabelValues(operation, collection, status).Inc()
}

func RecordRedisOperation(operation, status string, duration time.Duration) {
	redisOperationDuration.WithLabelValues(operation).Observe(duration.Seconds())
	redisOperationsTotal.WithLabelValues(operation, status).Inc()
}
