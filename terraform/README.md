# 🚀 E-Commerce Infrastructure Deployment (Terraform)

This directory provides automated Terraform infrastructure configurations to deploy the entire **E-Commerce Application** and observability stack across multiple cloud providers.

---

## ☁️ Supported Cloud Providers

Select the cloud provider of your choice:

| Provider | Folder | Resources Created | Guide |
| :--- | :--- | :--- | :--- |
| **Amazon Web Services (AWS)** | [`terraform/aws`](file:///r:/Devops%20territory/ecom/terraform/aws) | EC2 (`t3.medium`), 30GB gp3 EBS, Security Group, Automated Cloud-Init Bootstrap | [AWS Readme](file:///r:/Devops%20territory/ecom/terraform/aws/README.md) |
| **Google Cloud Platform (GCP)** | [`terraform/`](file:///r:/Devops%20territory/ecom/terraform) | Compute Engine VM (`e2-medium`), 30GB Persistent Disk, Firewall Rules, Startup Script | [GCP Readme](file:///r:/Devops%20territory/ecom/terraform/README.md) |

---

## 🛠️ GCP Infrastructure Overview

The root Terraform configuration provisions the following on Google Cloud Platform:

* **Compute Engine VM (`e2-medium`)**: Configured with 2 vCPUs and 4 GB RAM running **Ubuntu 22.04 LTS**.
* **Automated Startup Script**: Automatically configures the VM by installing:
  * **Docker** & **Docker Compose**
  * **SaltStack minion** (runs masterless local states)
  * Clones the `ecommerce-apps` repository and deploys the entire containerized stack via Docker Compose.
* **Firewall Rules**: Open traffic from the public internet for the following ports:
  * `4000`: E-Commerce Frontend Web UI
  * `9092`: Prometheus Metrics Dashboard
  * `3000`: Grafana Dashboard
  * `19999`: Netdata System Metrics
  * `3001` - `9090`: Application APIs (Catalog, Inventory, Orders, Shipping, Contact Support)
  * `4317` - `4318`: OpenTelemetry Collector (gRPC & HTTP)

---

## 📋 Prerequisites for GCP

1. **Terraform CLI** installed locally (`v1.0.0+`).
2. **Google Cloud SDK (gcloud)** installed and authenticated:
   ```bash
   gcloud auth application-default login
   ```
3. A GCP project created with the **Compute Engine API** enabled.

---

## 🚀 Quick Start Deployment (GCP)

Execute the following commands from the `terraform` directory:

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan the Deployment
```bash
terraform plan
```

### 3. Deploy the Infrastructure
```bash
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

---

## 🛑 Clean Up (GCP)

To tear down all resources created by GCP Terraform:
```bash
terraform destroy
```
