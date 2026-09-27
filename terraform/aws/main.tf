# Dynamic lookup for official Ubuntu 22.04 LTS AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC lookup (used if var.vpc_id is not specified)
data "aws_vpc" "default" {
  default = var.vpc_id == "" ? true : false
  id      = var.vpc_id != "" ? var.vpc_id : null
}

# Subnets lookup for the selected VPC
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  vpc_id             = data.aws_vpc.default.id
  selected_subnet_id = var.subnet_id != "" ? var.subnet_id : tolist(data.aws_subnets.selected.ids)[0]
}

# Security Group for E-commerce Application & Observability Stack
resource "aws_security_group" "ecom_sg" {
  name        = "${var.instance_name}-sg"
  description = "Allow inbound traffic for E-Commerce microservices, Web UI, Prometheus, Grafana, and OTel"
  vpc_id      = local.vpc_id

  # SSH Port
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # Standard HTTP & HTTPS
  ingress {
    description = "HTTP Web Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "HTTPS Web Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  # Frontend Web UI Gateway
  ingress {
    description = "E-Commerce Frontend UI Portal"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  # Observability & Monitoring Dashboards
  ingress {
    description = "Prometheus Server Dashboard"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "Netdata Dashboard"
    from_port   = 19999
    to_port     = 19999
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  # OpenTelemetry Collector (gRPC & HTTP receiver endpoints)
  ingress {
    description = "OpenTelemetry Collector gRPC Receiver"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "OpenTelemetry Collector HTTP Receiver"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  # Microservices Backend APIs
  ingress {
    description = "Product Catalog Service"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "Product Inventory Service"
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "Contact Support Service"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "Shipping & Handling Service"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  ingress {
    description = "Order Management Service"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_traffic_cidr
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# AWS EC2 VM Instance
resource "aws_instance" "ecom_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.selected_subnet_id
  vpc_security_group_ids      = [aws_security_group.ecom_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
    tags = {
      Name = "${var.instance_name}-root-disk"
    }
  }

  # User Data script to install Docker, Docker Compose, SaltStack, and start the application stack
  user_data = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "=== [1/6] Starting E-Commerce Stack Bootstrap on AWS ==="
    export DEBIAN_FRONTEND=noninteractive

    # 1. Update packages
    apt-get update -y
    apt-get install -y git curl gnupg lsb-release ca-certificates apt-transport-https

    # 2. Install Docker & Docker Compose Plugin
    echo "=== [2/6] Installing Docker & Docker Compose ==="
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod 644 /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Ensure standard docker-compose symlink works
    ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

    # Ensure docker group exists and grant access to standard users
    groupadd -f docker
    id -u prakritidev881 &>/dev/null || useradd -m -s /bin/bash -u 1000 prakritidev881
    usermod -aG docker prakritidev881
    usermod -aG docker ubuntu || true

    # 3. Install Salt-Call (Masterless Salt-Minion)
    echo "=== [3/6] Installing SaltStack Minion ==="
    curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring.asc https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
    chmod 644 /etc/apt/keyrings/salt-archive-keyring.asc
    echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring.asc arch=$(dpkg --print-architecture)] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" | tee /etc/apt/sources.list.d/salt.list
    apt-get update -y
    apt-get install -y salt-minion || true

    # Disable default background minion service (masterless execution only)
    systemctl stop salt-minion || true
    systemctl disable salt-minion || true

    # 4. Clone and configure repository
    echo "=== [4/6] Cloning Repository ==="
    mkdir -p /home/prakritidev881
    chown -R prakritidev881:prakritidev881 /home/prakritidev881

    sudo -u prakritidev881 git clone ${var.git_repo_url} /home/prakritidev881/ecommerce-apps || (cd /home/prakritidev881/ecommerce-apps && sudo -u prakritidev881 git pull origin master || true)
    sudo -u prakritidev881 git config --global --add safe.directory /home/prakritidev881/ecommerce-apps

    # Also link to /home/ubuntu for convenience if ubuntu user exists
    if [ -d "/home/ubuntu" ]; then
      ln -sf /home/prakritidev881/ecommerce-apps /home/ubuntu/ecommerce-apps
      chown -h ubuntu:ubuntu /home/ubuntu/ecommerce-apps || true
    fi

    # 5. Provision Stack (SaltStack State Apply or Docker Compose fallback)
    echo "=== [5/6] Deploying Application & Observability Services ==="
    if [ -d "/home/prakritidev881/ecommerce-apps/salt-stack/salt" ]; then
      echo "Applying SaltStack states..."
      salt-call --local --file-root=/home/prakritidev881/ecommerce-apps/salt-stack/salt --pillar-root=/home/prakritidev881/ecommerce-apps/salt-stack/pillar state.apply || true
    fi

    # Ensure docker-compose is started directly
    if [ -d "/home/prakritidev881/ecommerce-apps/docker-compose" ]; then
      echo "Starting services via Docker Compose..."
      cd /home/prakritidev881/ecommerce-apps/docker-compose
      docker-compose up -d --build
    fi

    echo "=== [6/6] E-Commerce Stack Bootstrap Complete! ==="
  EOT

  tags = {
    Name        = var.instance_name
    Type        = "Ecom-Host"
    Provisioner = "Terraform"
  }
}
