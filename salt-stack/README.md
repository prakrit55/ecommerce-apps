# SaltStack Environment Setup for E-commerce Application

This directory contains the SaltStack states and pillars to automatically provision, configure, and deploy the E-commerce microservices application using Docker Compose.

## Directory Structure

```text
salt-stack/
├── pillar/
│   ├── top.sls          # Maps minions to pillar configuration
│   └── ecom.sls         # Environment/deployment configuration values (db, paths, endpoints)
└── salt/
    ├── top.sls          # Main state map
    ├── docker/
    │   └── init.sls     # Installs Docker, Docker Compose, and registers service
    └── ecom/
        ├── init.sls     # Configures paths, templates .env, syncs contexts, runs compose
        └── files/
            ├── .env.jinja   # Jinja template for .env files
            └── docker-compose-config/
                ├── docker-compose.yml
                ├── otel-collector-config.yaml
                └── prometheus.yml
```

## How It Works

1. **Docker Installation**: The `docker` state installs necessary dependencies, Docker Engine, and Docker Compose on the minion (supporting Ubuntu, Debian, CentOS, Rocky, and RHEL).
2. **Environment Configuration**: The `ecom` state reads configurations from the Salt Pillar (`pillar/ecom.sls`) and renders the `.env` configuration file on the minion.
3. **Codebase Syncing**: The state syncs the docker-compose config files and all source directories to the application folder on the minion (`/opt/ecom` by default) to fulfill build context dependencies.
4. **Service Execution**: The state triggers a docker-compose deployment (`docker-compose up -d --build`) whenever changes are made to the configuration templates or source folders.

## Setup Instructions

### 1. Configure Salt Master
Update your Salt Master's configuration file `/etc/salt/master` to specify the file and pillar roots pointing to this directory:

```yaml
file_roots:
  base:
    - /path/to/ecom/salt-stack/salt

pillar_roots:
  base:
    - /path/to/ecom/salt-stack/pillar
```

*Note: Restart your `salt-master` service after modifying the config:*
```bash
sudo systemctl restart salt-master
```

### 2. Configure Pillars (Environment variables)
Before deploying, you can customize database credentials, application directories, and telemetry endpoints in [pillar/ecom.sls](file:///r:/Devops%20territory/ecom/salt-stack/pillar/ecom.sls):

```yaml
ecom:
  app_dir: /opt/ecom
  postgres:
    user: postgres
    password: postgres
    db: postgres
  otel:
    exporter_endpoint: http://otel-collector:4317
```

### 3. Apply the States
Run the following command on your Salt Master to deploy the application on all targeted minions:

```bash
salt '*' state.apply
```

If you are testing locally on a single machine running `salt-minion` in masterless mode:
```bash
salt-call --local state.apply
```
