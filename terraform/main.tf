# Compute Engine VM Instance
resource "google_compute_instance" "ecom_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["ecom-server", "http-server"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = 30 # 30 GB disk space
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Allocate a public ephemeral IP
    }
  }

  metadata = {
    // Startup script to automate Docker, Docker Compose, SaltStack installation and apply states
    startup-script = <<-EOT
      #!/usr/bin/env bash
      set -euo pipefail

      # 1. Update packages
      apt-get update
      apt-get install -y git curl gnupg lsb-release

      # 2. Install Docker & Docker Compose
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

      # Ensure standard docker-compose command works
      ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

      # Ensure docker group exists and user is added to it
      groupadd -f docker
      id -u prakritidev881 &>/dev/null || useradd -m -s /bin/bash -u 1000 prakritidev881
      usermod -aG docker prakritidev881

      # 3. Install Salt-Call (Masterless Salt-Minion)
      curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring.gpg https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
      echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" | tee /etc/apt/sources.list.d/salt.list
      apt-get update
      apt-get install -y salt-minion

      # Disable default background minion service (masterless execution only)
      systemctl stop salt-minion || true
      systemctl disable salt-minion || true

      # 4. Clone and set up repository
      mkdir -p /home/prakritidev881
      git clone https://github.com/prakrit55/ecommerce-apps.git /home/prakritidev881/ecommerce-apps
      chown -R 1000:1000 /home/prakritidev881/ecommerce-apps

      # 5. Apply SaltState
      salt-call --local --file-root=/home/prakritidev881/ecommerce-apps/salt-stack/salt --pillar-root=/home/prakritidev881/ecommerce-apps/salt-stack/pillar state.apply
    EOT
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Firewall Rule to Allow E-commerce UI, Microservices, Prometheus, and OTel Ports
resource "google_compute_firewall" "allow_ecom_traffic" {
  name    = "allow-ecom-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["4000", "9092", "3001", "3002", "8080", "8000", "9090", "4317", "4318"]
    # 4000: UI Portal
    # 9092: Prometheus Dashboard
    # 3001: Product Catalog
    # 3002: Product Inventory
    # 8080: Shipping Handling
    # 8000: Contact Support
    # 9090: Order Management
    # 4317-4318: OpenTelemetry Collector (gRPC & HTTP)
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ecom-server"]
}
