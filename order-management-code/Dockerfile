# Use the official Maven runtime with JDK 17 as a base image
FROM maven:3.6.3-openjdk-17-slim

# Set the working directory inside the container
WORKDIR /app

# Download the OpenTelemetry Java Agent
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.5.0/opentelemetry-javaagent.jar /app/opentelemetry-javaagent.jar

# Copy the project files
COPY . .

# Expose the port that the application listens on
EXPOSE 9090

# Set environment variables to enable the OpenTelemetry agent and configure service name
ENV JAVA_TOOL_OPTIONS="-javaagent:/app/opentelemetry-javaagent.jar"
ENV OTEL_SERVICE_NAME="order-management"
ENV OTEL_TRACES_EXPORTER="otlp"
ENV OTEL_METRICS_EXPORTER="otlp"
ENV OTEL_LOGS_EXPORTER="none"

## 5. Define the command to run when the container starts.
CMD ["mvn", "spring-boot:run"]