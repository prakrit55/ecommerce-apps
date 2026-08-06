# 🚀 E-Commerce Infrastructure Deployment (Terraform)

This directory contains the Terraform configuration to provision a Google Compute Engine (GCE) VM instance and configure the networking firewall rules required to run the **E-Commerce Application** stack.

---

## 🛠️ Infrastructure Overview

The configuration provisions the following resources on Google Cloud Platform:

* **Compute Engine VM (`e2-medium`)**: Configured with 2 vCPUs and 4 GB RAM running **Ubuntu 22.04 LTS**.
* **Automated Startup Script**: Automatically configures the VM by installing:
  * **Docker** & **Docker Compose**
  * **SaltStack minion** (runs masterless local states)
  * Clones the `ecommerce-apps` repository and deploys the entire containerized stack via Docker Compose.
* **Firewall Rules**: Open traffic from the public internet for the following ports:
  * `4000`: E-Commerce Frontend Web UI
  * `9092`: Prometheus Metrics Dashboard
  * `3001` - `9090`: Application APIs (Catalog, Inventory, Orders, Shipping, Contact Support)
  * `4317` - `4318`: OpenTelemetry Collector (gRPC & HTTP)

---

## 📋 Prerequisites

Before running this Terraform configuration, ensure you have:

1. **Terraform CLI** installed locally (v1.0.0+).
2. **Google Cloud SDK (gcloud)** installed and authenticated:
   ```bash
   gcloud auth application-default login
   ```
3. A GCP project created with the **Compute Engine API** enabled.

---

## 🚀 Quick Start Deployment

Execute the following commands from the `terraform` directory:

### 1. Initialize Terraform
Downloads the required Google Cloud providers and initializes the backend:
```bash
terraform init
```

### 2. Plan the Deployment
Verify the resources that will be created:
```bash
terraform plan
```

### 3. Deploy the Infrastructure
Apply the configuration to provision the VM and firewall rules:
```bash
terraform apply
```
*Note: The project ID defaults to `k8s-staging-252732`. You can override variables if needed (e.g. `terraform apply -var="machine_type=e2-standard-2"`).*

---

## 🚪 Outputs & Access

Once `terraform apply` completes successfully, it will print the following outputs:

* **`instance_public_ip`**: The public IPv4 address of the VM instance.
* **`application_ui_url`**: URL to access the React Frontend & API Gateway (`http://<IP>:4000`).
* **`prometheus_dashboard_url`**: URL to access the Prometheus Dashboard (`http://<IP>:9092`).

---

## 🛑 Clean Up

To tear down all resources created by this configuration and avoid GCP charges:
```bash
terraform destroy
```
