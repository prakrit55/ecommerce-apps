# E-Commerce Microservices Local Deployment

This folder contains a complete Docker Compose environment to spin up all services and their dependent databases locally, with OpenTelemetry tracing and metrics integrated via Prometheus and Jaeger.

## Services Map

| Service Name | Port | Description | Language / Stack |
|---|---|---|---|
| **ecommerce-ui** | `4000` | Gateway & Frontend Web UI | Node.js / Express / React |
| **product-catalog** | `3001` | Catalog of products | Node.js / Express / MongoDB / Redis |
| **product-inventory** | `3002` | Product stock inventory | Python / Flask / PostgreSQL |
| **order-management** | `9090` | Managing shopping cart and orders | Java / Spring Boot / PostgreSQL |
| **shipping-handling** | `8080` | Calculating shipping fees | Go / PostgreSQL |
| **contact-support** | `8000` | Contact forms submission | Python / Flask / PostgreSQL |
| **otel-collector** | `4317` / `4318` | OpenTelemetry Collector receiver | Collector |
| **prometheus** | `9092` | Metrics monitoring Web UI | Prometheus |
| **jaeger** | `16686` | OpenTelemetry Trace Dashboard | Go / Tracing collector |
| **postgres** | `5432` | Shared relational database | PostgreSQL |
| **mongodb** | `27017` | Catalog document database | MongoDB |
| **redis** | `6379` | Catalog cache | Redis |

---

## Prerequisites

Ensure you have Docker and Docker Compose installed:
*   [Docker Desktop](https://www.docker.com/products/docker-desktop/)

---

## How to Run

1.  **Start Services**:
    From this directory, run:
    ```bash
    docker compose up --build -d
    ```
    This will build the local Dockerfiles and start all containers in detached mode.

2.  **Verify Setup**:
    Check if all containers are running successfully:
    ```bash
    docker compose ps
    ```

3.  **Access the Applications**:
    *   **Ecommerce UI**: [http://localhost:4000](http://localhost:4000)
    *   **Jaeger UI (Traces)**: [http://localhost:16686](http://localhost:16686)
    *   **Prometheus UI (Metrics)**: [http://localhost:9092](http://localhost:9092)

4.  **Stop Services**:
    ```bash
    docker compose down -v
    ```
    *(Note: `-v` will also clean up local database volumes if you want a fresh restart.)*

---

## Verifying Telemetry/Metrics/Traces

### Traces in Jaeger
1.  Open [http://localhost:4000](http://localhost:4000) and place some items in the cart or submit a support query.
2.  Open Jaeger UI at [http://localhost:16686](http://localhost:16686).
3.  Select a service (e.g. `order-management` or `shipping-service`) from the **Service** dropdown, and click **Find Traces**.

### Metrics in Prometheus
1.  Generate some traffic by interacting with the UI.
2.  Open Prometheus UI at [http://localhost:9092](http://localhost:9092).
3.  Type a metric name in the search query box (e.g. `otelcol_process_uptime` or `http_server_active_requests` or any other application metric).
4.  Click **Execute** and select the **Graph** tab to see your metrics plotted over time.
