FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy all source code first
COPY . .

# Tidy and download dependencies
RUN go mod tidy
RUN go mod download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o payment-service ./cmd/main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/payment-service .

EXPOSE 8080

CMD ["./payment-service"]

