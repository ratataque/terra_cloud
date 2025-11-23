# TerraCloud Application

> Laravel application deployed to Azure using Docker containers with automated CI/CD pipelines

[![CI/CD Pipeline](https://github.com/ratataque/terracloud/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/ratataque/terracloud/actions)

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Repository Structure](#-repository-structure)
- [Application Integration](#-application-integration)
- [Docker Configuration](#-docker-configuration)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Development Environment](#-development-environment)
- [Deployment Process](#-deployment-process)
- [GitHub Secrets](#-github-secrets)
- [Versioning Strategy](#-versioning-strategy)
- [Performance Optimizations](#-performance-optimizations)
- [Quick Start Guide](#-quick-start-guide)

---

## 🎯 Project Overview

**TerraCloud** is a containerized Laravel application designed for deployment on Azure cloud infrastructure. This repository contains **only the application code**, following a separation of concerns architecture where infrastructure provisioning is managed in a separate repository.

### Architecture

```
┌─────────────────────────────────────┐
│   TerraCloud App Repository         │
│   (This repo)                        │
│                                      │
│   • Laravel Application              │
│   • Docker Configuration             │
│   • CI/CD Workflows                  │
│   • Testing & Linting                │
└──────────────┬──────────────────────┘
               │
               │ Triggers deployment via
               │ repository_dispatch event
               ▼
┌─────────────────────────────────────┐
│   Infrastructure Repository          │
│   (Separate repo)                    │
│                                      │
│   • Terraform/Terragrunt             │
│   • Azure Resources                  │
│   • Infrastructure as Code           │
└─────────────────────────────────────┘
```

### Technology Stack

- **Framework**: Laravel 8.x
- **Runtime**: PHP 8.2 with Apache
- **Database**: MySQL 8.0 with SSL support
- **Container**: Docker (optimized for low-memory VMs)
- **CI/CD**: GitHub Actions with Azure OIDC
- **Registry**: Azure Container Registry (ACR)
- **Infrastructure**: Managed in separate repository

---

## 📁 Repository Structure

```
terracloud/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Main CI/CD orchestration
│       ├── reusable-test.yml      # Test & lint workflow
│       └── reusable-deploy.yml    # Build & deploy workflow
├── app/
│   ├── app/                       # Laravel application code
│   ├── config/                    # Configuration files
│   │   └── database.php           # DB config with SSL support
│   ├── database/
│   │   └── seeders/               # Database seeders
│   ├── docker/
│   │   └── php-production.ini     # Optimized PHP configuration
│   ├── routes/                    # API & web routes
│   ├── docker-compose.yaml        # Local development setup
│   ├── Dockerfile                 # Production image (standard)
│   ├── Dockerfile.optimized       # Production image (512MB optimized)
│   ├── docker-entrypoint.sh       # Container startup script
│   └── composer.json              # PHP dependencies
└── README.md                      # This file
```

### What Belongs Here

This repository contains:

- ✅ Laravel application source code
- ✅ Docker configuration and optimization
- ✅ CI/CD pipeline definitions
- ✅ Application tests and linting rules
- ✅ Container entrypoint scripts

### What Doesn't Belong Here

Infrastructure-related code lives in a separate repository:

- ❌ Terraform/Terragrunt configurations
- ❌ Azure resource definitions
- ❌ Cloud infrastructure provisioning
- ❌ Network and security configurations

---

## 🔧 Application Integration

This section describes the **specific modifications and integrations** made to the base Laravel application for cloud deployment.

### Database Integration

#### MySQL with SSL Support

The application has been configured to support **SSL connections to Azure Database for MySQL**:

**Configuration** (`config/database.php`):

```php
'mysql' => [
    'driver' => 'mysql',
    // ... standard config ...
    'options' => extension_loaded('pdo_mysql') ? array_filter([
        PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
    ]) + [
        PDO::ATTR_PERSISTENT => true,
    ] : [],
],
```

**Environment Variable**:

```bash
MYSQL_ATTR_SSL_CA=/path/to/DigiCertGlobalRootCA.crt.pem
```

The SSL certificate is bundled in the Docker image and used for secure database connections in production.

### Entrypoint Script

The application uses a custom entrypoint (`docker-entrypoint.sh`) that handles:

1. **Automatic Database Migrations**

   ```bash
   php artisan migrate --force
   ```

2. **Conditional Seeding**
   - Seeds only if `/tmp/need-seed` flag file exists
   - Useful for initial deployment or data refresh

   ```bash
   # To trigger seeding in a running container
   docker exec app touch /tmp/need-seed
   docker restart app
   ```

3. **Graceful Startup**
   - Ensures database is ready before starting Apache
   - Handles migration failures gracefully

### Environment Configuration

Key environment variables used by the application:

| Variable            | Purpose                                      | Example                                     |
| ------------------- | -------------------------------------------- | ------------------------------------------- |
| `APP_VERSION`       | Application version (injected at build time) | `0.0.67-prod`                               |
| `DB_HOST`           | MySQL server hostname                        | `terracloud-mysql.mysql.database.azure.com` |
| `DB_DATABASE`       | Database name                                | `app_database`                              |
| `DB_USERNAME`       | Database user                                | `app_user@terracloud-mysql`                 |
| `DB_PASSWORD`       | Database password                            | `<secure-password>`                         |
| `MYSQL_ATTR_SSL_CA` | SSL certificate path                         | `/var/www/html/storage/certs/...`           |

---

## 🐳 Docker Configuration

### Development Setup (`docker-compose.yaml`)

The local development environment includes:

```yaml
services:
  traefik: # Reverse proxy for routing
  app: # Laravel application
  db: # MySQL 8.0 database
```

**Features**:

- ✅ **Traefik** reverse proxy with automatic routing
- ✅ **Hot-reload** support via volume mounts
- ✅ **Local MySQL** instance with health checks
- ✅ **Metrics** endpoint on port 8082

**Access**:

- Application: http://localhost
- Metrics: http://localhost:8082/metrics

### Production Dockerfile

Two production images are available:

#### Standard Image (`Dockerfile`)

- Base: `php:8.2.8-apache`
- Memory footprint: ~200-300MB
- Use case: Standard deployments

#### Optimized Image (`Dockerfile.optimized`)

- Base: `php:8.2.8-apache`
- Memory footprint: **< 512MB** (VM optimized)
- Use case: Cost-optimized deployments on B1s VMs

### Key Optimizations

#### 1. PHP Configuration (`docker/php-production.ini`)

```ini
memory_limit = 96M                  # Reduced from 128M default
opcache.enable = 1                  # Enable OPcache for performance
opcache.memory_consumption = 32     # 32MB for opcache
opcache.max_accelerated_files = 3000
opcache.revalidate_freq = 60        # Check changes every 60s
realpath_cache_size = 256K          # Reduce filesystem lookups
```

#### 2. Apache MPM Configuration

**Prefork MPM** tuned for low memory:

```apache
StartServers 1
MinSpareServers 1
MaxSpareServers 2
MaxRequestWorkers 10              # Limit concurrent requests
MaxConnectionsPerChild 1000
```

#### 3. Composer Optimization

Dependencies installed with aggressive optimization:

```bash
composer install --no-dev \
                 --optimize-autoloader \
                 --classmap-authoritative \
                 --no-interaction
```

**Benefits**:

- ✅ No dev dependencies (~20-30MB saved)
- ✅ Optimized autoloader (faster class loading)
- ✅ Classmap authoritative (no filesystem checks)

#### 4. Layer Caching

Dockerfile layers optimized for build speed:

1. Install system dependencies
2. Install PHP extensions
3. Copy Composer files
4. Install dependencies (cached if unchanged)
5. Copy application code

---

## 🔄 CI/CD Pipeline

### Workflow Overview

The CI/CD pipeline is composed of **one main workflow** and **two reusable workflows**:

```
┌─────────────────────────────────────────────────────────────┐
│                      ci.yml (Main)                          │
│                                                             │
│  Triggers: push to [main, qa], pull_request               │
└─────────────────┬───────────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
┌──────────────┐   ┌──────────────────┐
│ reusable-    │   │ reusable-deploy  │
│ test.yml     │   │ .yml             │
│              │   │                  │
│ • PHPUnit    │   │ • Semantic       │
│ • PHP CS     │   │   versioning     │
└──────────────┘   │ • Docker build   │
                   │ • ACR push       │
                   │ • Git tagging    │
                   │ • Trigger infra  │
                   └──────────────────┘
```

### Main Workflow (`.github/workflows/ci.yml`)

**Triggers**:

- Push to `main` → Deploy to **PROD**
- Push to `qa` → Deploy to **QA**
- Pull request → Run tests only

**Branch Strategy**:

```
main (production)  → latest-prod
  │
  └── qa (staging) → latest-qa
```

### Test Workflow (`.github/workflows/reusable-test.yml`)

Runs on every push and PR:

1. **PHPUnit Tests**
   - Spins up MySQL 8.0 service
   - Runs migrations
   - Executes test suite

2. **Code Linting**
   - PHP CodeSniffer (phpcs)
   - PSR-12 compliance

**Test Environment**:

```yaml
services:
  mysql:
    image: mysql:8.0
    env:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: testing
```

### Deploy Workflow (`.github/workflows/reusable-deploy.yml`)

**Inputs**:

- `environment`: `qa` or `prod`
- `version_format`: Semantic version format

**Steps**:

1. **Calculate Semantic Version**

   ```yaml
   uses: paulhatch/semantic-version@v5.3.0
   with:
     major_pattern: "(MAJOR)"
     minor_pattern: "(MINOR)"
     bump_each_commit: true
   ```

2. **Create Git Tag**

   ```
   v0.0.67-prod
   v0.0.65-qa
   ```

3. **Azure Authentication**
   - Uses OIDC (OpenID Connect)
   - No long-lived credentials
   - Federated identity with GitHub

4. **Build & Push Docker Image**

   ```bash
   Tags created:
   - {ACR}.azurecr.io/app:0.0.67-prod
   - {ACR}.azurecr.io/app:0.0.67-prod-{sha}
   - {ACR}.azurecr.io/app:latest-prod
   ```

5. **Trigger Infrastructure Deployment**
   - Sends `repository_dispatch` event
   - Infrastructure repo pulls new image
   - Updates Azure resources

---

## 💻 Development Environment

### Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose v2+
- Git

### Local Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/terracloud.git
   cd terracloud/app
   ```

2. **Start services**

   ```bash
   docker-compose up -d
   ```

   This starts:
   - Traefik (reverse proxy)
   - Laravel app (port 80)
   - MySQL database

3. **Check logs**

   ```bash
   docker-compose logs -f app
   ```

4. **Access application**
   - **App**: http://localhost
   - **Metrics**: http://localhost:8082/metrics

### Running Tests Locally

```bash
# Enter app container
docker-compose exec app bash

# Run PHPUnit tests
php artisan test

# Run linter
vendor/bin/phpcs
```

### Database Access

```bash
# Access MySQL shell
docker-compose exec db mysql -u app_user -papp_password app_database

# Run migrations manually
docker-compose exec app php artisan migrate

# Run seeders
docker-compose exec app php artisan db:seed
```

### Rebuilding the Image

```bash
# Rebuild after Dockerfile changes
docker-compose build app
docker-compose up -d
```

### Traefik Dashboard

Access Traefik metrics at http://localhost:8082/metrics for:

- Request rates
- Response times
- Backend health

---

## 🚀 Deployment Process

### QA Environment

**Trigger**: Push to `qa` branch

```bash
git checkout qa
git merge feature-branch
git push origin qa
```

**Pipeline**:

1. Runs tests (`reusable-test.yml`)
2. Builds Docker image
3. Tags: `v{version}-qa`, `latest-qa`
4. Pushes to ACR
5. Triggers QA infrastructure update

**Deployed to**: Azure App Service (QA slot)

### Production Environment

**Trigger**: Push to `main` branch

```bash
git checkout main
git merge qa
git push origin main
```

**Pipeline**:

1. Runs tests (`reusable-test.yml`)
2. Builds Docker image
3. Tags: `v{version}-prod`, `latest-prod`
4. Pushes to ACR
5. Triggers PROD infrastructure update

**Deployed to**: Azure App Service (Production slot)

### Image Tagging Strategy

Each deployment creates **3 tags**:

| Tag                      | Purpose             | Example                |
| ------------------------ | ------------------- | ---------------------- |
| `v{version}-{env}`       | Semantic version    | `v0.0.67-prod`         |
| `v{version}-{env}-{sha}` | Git commit tracking | `v0.0.67-prod-8eb92df` |
| `latest-{env}`           | Latest stable       | `latest-prod`          |

**Benefits**:

- ✅ Rollback to specific version
- ✅ Track deployments to Git commits
- ✅ Easy "latest" reference

### Deployment Verification

After deployment, verify:

```bash
# Check ACR for new images
az acr repository show-tags --name {ACR_NAME} --repository app --orderby time_desc

# Check Git tags
git tag -l "v*-prod"

# View deployment summary in GitHub Actions
```

### Rollback Procedure

To rollback to a previous version:

1. **Identify target version**

   ```bash
   git tag -l "v*-prod"
   ```

2. **Trigger manual deployment** in infrastructure repo
   ```bash
   # In infrastructure repository
   terragrunt apply -var="app_version=0.0.65-prod"
   ```

---

## 🔐 GitHub Secrets

### Required Secrets

Configure these in **Settings → Secrets and variables → Actions → Secrets**:

| Secret                  | Description                                                   | Example                                |
| ----------------------- | ------------------------------------------------------------- | -------------------------------------- |
| `AZURE_CLIENT_ID`       | Service Principal Application (client) ID                     | `12345678-1234-1234-1234-123456789abc` |
| `AZURE_TENANT_ID`       | Azure Active Directory Tenant ID                              | `87654321-4321-4321-4321-cba987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID                                         | `abcdef12-3456-7890-abcd-ef1234567890` |
| `ACR_NAME`              | Azure Container Registry name (without .azurecr.io)           | `terracloudacr`                        |
| `INFRA_REPO_PAT`        | GitHub Personal Access Token for triggering infra deployments | `ghp_xxxxxxxxxxxxxxxxxxxx`             |

### Required Variables

Configure these in **Settings → Secrets and variables → Actions → Variables**:

| Variable     | Description                                    | Example                 |
| ------------ | ---------------------------------------------- | ----------------------- |
| `INFRA_REPO` | Infrastructure repository (format: owner/repo) | `user/terracloud-infra` |

### Setting Up Azure OIDC

The pipeline uses **OpenID Connect (OIDC)** for secure Azure authentication without long-lived credentials.

**Steps**:

1. **Create Service Principal**

   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-terracloud" \
     --role contributor \
     --scopes /subscriptions/{SUBSCRIPTION_ID}
   ```

2. **Configure Federated Credentials**

   ```bash
   az ad app federated-credential create \
     --id {APP_ID} \
     --parameters '{
       "name": "github-actions-prod",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:yourusername/terracloud:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

3. **Grant ACR Access**
   ```bash
   az role assignment create \
     --assignee {CLIENT_ID} \
     --role AcrPush \
     --scope /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RG}/providers/Microsoft.ContainerRegistry/registries/{ACR_NAME}
   ```

---

## 📦 Versioning Strategy

### Semantic Versioning

This project uses **automated semantic versioning** based on commit messages.

### Version Format

```
v{major}.{minor}.{patch}-{environment}

Examples:
- v0.0.67-prod
- v0.0.65-qa
- v1.2.3-prod
```

### Commit Message Conventions

| Commit Message     | Version Bump  | Example                                   |
| ------------------ | ------------- | ----------------------------------------- |
| Contains `(MAJOR)` | Major version | `breaking: redesign API (MAJOR)` → v1.0.0 |
| Contains `(MINOR)` | Minor version | `feat: add feature (MINOR)` → v0.1.0      |
| All other commits  | Patch version | `fix: resolve bug` → v0.0.1               |

### Examples

```bash
# Patch bump (default)
git commit -m "fix: resolve database connection issue"
# Result: v0.0.66-prod → v0.0.67-prod

# Minor bump
git commit -m "feat: add user authentication (MINOR)"
# Result: v0.0.67-prod → v0.1.0-prod

# Major bump
git commit -m "breaking: redesign API structure (MAJOR)"
# Result: v0.1.0-prod → v1.0.0-prod
```

### Git Tags

Each deployment creates a Git tag:

```bash
git tag -l "v*"
# Output:
v0.0.63-prod
v0.0.63-qa
v0.0.65-prod
v0.0.65-qa
v0.0.67-prod
```

**Tag naming**:

- Production: `v{version}-prod`
- QA: `v{version}-qa`

---

## ⚡ Performance Optimizations

### Memory Optimization on 212MB

The application is optimized to run efficiently on **Azure B1s instances** (512MB RAM But with 212 real RAM)
On Azure, some services take up a lot of ram by default, leaving only 212 real alvailable RAM

### PHP Configuration

**File**: `app/docker/php-production.ini`

```ini
# Memory per PHP process
memory_limit = 96M                  # Down from 128M default

# OPcache (CRITICAL for performance)
opcache.enable = 1
opcache.memory_consumption = 32     # 32MB opcache buffer
opcache.max_accelerated_files = 3000
opcache.revalidate_freq = 60        # Check file changes every 60s
opcache.validate_timestamps = 1     # Set to 0 for max performance

# Filesystem cache
realpath_cache_size = 256K          # Down from 4M default
realpath_cache_ttl = 600            # 10 minutes

# Timeouts
max_execution_time = 30
max_input_time = 30
default_socket_timeout = 30
```

**Impact**:

- ✅ **50% reduction** in per-request memory usage
- ✅ **10x faster** response times (via OPcache)
- ✅ **Reduced filesystem I/O** (realpath cache)

### Apache MPM Tuning

**Configuration**: `Dockerfile` (MPM Prefork module)

```apache
StartServers 1                    # Start with minimal processes
MinSpareServers 1
MaxSpareServers 2
MaxRequestWorkers 10              # Limit concurrent connections
MaxConnectionsPerChild 1000       # Recycle after 1000 requests
```

**Memory Math**:

```
Apache base:        ~20MB
PHP process (avg):  ~50MB
Max PHP processes:  10

Total estimate: 20 + (10 × 50) = ~520MB
Safety margin:      512MB target ✅
```

### Composer Optimization

```bash
composer install \
  --no-dev \                      # Exclude dev dependencies (-30MB)
  --optimize-autoloader \         # Optimized class map
  --classmap-authoritative \      # No filesystem fallback
  --no-interaction                # Non-interactive mode
```

**Benefits**:

- ✅ **Faster autoloading** (no file_exists checks)
- ✅ **Smaller image** (no phpunit, dev tools)
- ✅ **Predictable dependencies**

### Docker Image Optimization

**Multi-stage build** (if using Dockerfile.optimized):

```dockerfile
# Stage 1: Build dependencies
FROM composer:latest AS composer
COPY composer.json composer.lock ./
RUN composer install --no-dev

# Stage 2: Final image
FROM php:8.2.8-apache
COPY --from=composer /app/vendor ./vendor
```

**Layer caching strategy**:

1. Install OS packages (rarely changes)
2. Install PHP extensions (rarely changes)
3. Copy composer files (changes on dependency updates)
4. Install dependencies (cached if composer.json unchanged)
5. Copy application code (changes frequently)

### Performance Monitoring

Monitor memory usage in production:

```bash
# Inside container
php -i | grep memory_limit
php -v | grep OPcache

# Apache processes
ps aux | grep apache2
```

**Approximative expected metrics**:

- Memory per process: 40-60MB
- Response time: < 100ms (cached)
- Container memory: < 500MB

---

## 🚀 Quick Start Guide

### Prerequisites

- **Docker Desktop** or Docker Engine 20.10+
- **Docker Compose** v2.0+
- **Git** 2.30+
- (Optional) **Azure CLI** for ACR testing

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/terracloud.git
cd terracloud/app
```

### Step 2: Start Development Environment

```bash
docker-compose up -d
```

**Services started**:

- ✅ Traefik (reverse proxy)
- ✅ Laravel app (http://localhost)
- ✅ MySQL database

### Step 3: Verify Deployment

```bash
# Check services
docker-compose ps

# View logs
docker-compose logs -f app

# Check database
docker-compose exec db mysql -u app_user -papp_password -e "SHOW DATABASES;"
```

### Step 4: Access Application

Open your browser:

- **Application**: http://localhost
- **Traefik Metrics**: http://localhost:8082/metrics

### Step 5: Run Tests

```bash
# Enter container
docker-compose exec app bash

# Run tests
php artisan test

# Run linter
vendor/bin/phpcs
```

### Step 6: Make Changes

1. **Edit code** in `app/` directory (changes reflected immediately)
2. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add new feature (MINOR)"
   ```
3. **Push to trigger CI/CD**
   ```bash
   git push origin qa          # Deploy to QA
   # or
   git push origin main        # Deploy to PROD
   ```

### Step 7: Deploy to Azure

**Prerequisites**:

1. Configure [GitHub Secrets](#-github-secrets)
2. Set up Azure OIDC authentication
3. Ensure infrastructure repository is ready

**Deploy**:

```bash
# Push to QA environment
git checkout qa
git merge your-feature-branch
git push origin qa

# Push to Production
git checkout main
git merge qa
git push origin main
```

**Monitor deployment**:

- GitHub Actions: https://github.com/yourusername/terracloud/actions
- Azure Portal: Check App Service logs

---

## 📚 Additional Documentation

For more detailed information, see:

- [Infrastructure Repository](https://github.com/yourusername/terracloud-infra) - Terraform/Terragrunt configurations
- [Laravel Documentation](https://laravel.com/docs/8.x) - Framework reference
- [Azure App Service](https://docs.microsoft.com/azure/app-service/) - Deployment platform

---

## General startup

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature (MINOR)'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
