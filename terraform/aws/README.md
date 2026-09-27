# 🚀 E-Commerce Infrastructure Deployment on AWS (Terraform)

This directory contains the Terraform configuration to provision an **AWS EC2 instance (`t3.medium`)** with attached EBS storage, automated cloud-init bootstrap script, and a tailored Security Group to run the full **E-Commerce Application** and observability pipeline.

---

## 🛠️ Infrastructure Overview

The configuration provisions the following resources on AWS:

* **EC2 VM Instance (`t3.medium`)**:
  * 2 vCPUs, 4 GiB RAM.
  * Official **Ubuntu 22.04 LTS (Jammy Jellyfish)** AMI (queried dynamically via Canonical owner ID).
  * **30 GB gp3** encrypted EBS root volume with automated cleanup on termination.
  * Associated with an auto-assigned public IPv4 address.
* **Automated Cloud-Init / User-Data Bootstrapping**:
  * Automatically installs **Docker CE**, **Containerd**, and **Docker Compose plugin**.
  * Installs **SaltStack minion** (masterless configuration mode).
  * Clones the `ecommerce-apps` repository and boots the full microservices stack and observability tools via Docker Compose.
* **AWS Security Group (`ecom-app-instance-sg`)**:
  * `22`: SSH Remote Access.
  * `4000`: E-Commerce Frontend Web UI Portal.
  * `9092`: Prometheus Metrics Server & Dashboard.
  * `3000`: Grafana Observability Dashboard.
  * `19999`: Netdata Real-time System Metrics.
  * `4317` & `4318`: OpenTelemetry Collector (gRPC & HTTP).
  * `3001` - `9090`: Microservices REST APIs (Catalog, Inventory, Orders, Shipping, Contact Support).
  * `80` & `443`: Standard HTTP/HTTPS.

---

## 📋 Prerequisites

Before running this Terraform configuration, make sure you have:

1. **Terraform CLI** installed locally (`>= 1.0.0`).
2. **AWS CLI** configured with appropriate credentials:
   ```bash
   aws configure
   ```
   Or export environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

---

## 🚀 Quick Start Deployment

Execute the following commands from `terraform/aws`:

### 1. Initialize Terraform
Downloads the AWS provider and initializes state backend:
```bash
terraform init
```

### 2. (Optional) Customize Variables
Create a `terraform.tfvars` file if you wish to override default variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Review Execution Plan
```bash
terraform plan
```

### 4. Deploy the Infrastructure
```bash
terraform apply
```
Type `yes` when prompted to confirm the creation of resources.

---

## 🚪 Outputs & Access Points

Once `terraform apply` finishes, it displays the following outputs:

| Output Name | Description | Example URL / Value |
| :--- | :--- | :--- |
| **`instance_public_ip`** | Public IP address of the EC2 instance | `54.210.12.34` |
| **`application_ui_url`** | E-Commerce Web UI Portal | `http://<IP>:4000` |
| **`prometheus_dashboard_url`** | Prometheus Metrics Dashboard | `http://<IP>:9092` |
| **`grafana_dashboard_url`** | Grafana Dashboards | `http://<IP>:3000` |
| **`netdata_dashboard_url`** | Netdata System Monitor | `http://<IP>:19999` |
| **`ssh_command`** | SSH connection command | `ssh -i <key.pem> ubuntu@<IP>` |

---

## ⚙️ Configuration Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `aws_region` | AWS Region for the deployment | `us-east-1` |
| `instance_name` | Name tag for EC2 instance & Security Group | `ecom-app-instance` |
| `instance_type` | EC2 machine type | `t3.medium` |
| `root_volume_size` | Size of EBS root volume in GiB | `30` |
| `root_volume_type` | Type of EBS root volume | `gp3` |
| `key_name` | Existing AWS Key Pair for SSH access | `""` *(optional)* |
| `allowed_ssh_cidr` | Allowed CIDR blocks for SSH | `["0.0.0.0/0"]` |
| `allowed_traffic_cidr` | Allowed CIDR blocks for web and dashboard ports | `["0.0.0.0/0"]` |

---

## 🛑 Teardown & Clean Up

To destroy all provisioned AWS resources and prevent unwanted charges:
```bash
terraform destroy
```
