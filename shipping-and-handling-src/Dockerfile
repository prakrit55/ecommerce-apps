# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o shipping-service .

# Run stage
FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/shipping-service .

EXPOSE 8080

# Set environment variables for OpenTelemetry configuration
ENV OTEL_SERVICE_NAME="shipping-service"
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"

CMD ["./shipping-service"]
