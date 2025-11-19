# TerraCloud Application

Laravel application deployed to Azure using Docker containers.

## Repository Structure

This repository contains **only the application code**. Infrastructure and deployment are managed in a separate repository.

## CI/CD Pipeline

### Continuous Integration (this repo)

**Workflow**: `.github/workflows/ci.yml`

On every push to `main`:

1. ✅ Run tests (PHPUnit + MySQL)
2. ✅ Run linting (PHP CodeSniffer)
3. 🏗️ Build Docker image
4. 📦 Push to ACR with semantic versioning
5. 🏷️ Tags: `v{major}.{minor}.{patch}`, `v{version}-{sha}`, `latest`

### Versioning Strategy

**Semantic Versioning** is automated:

- Bump **major**: Include `(MAJOR)` in commit message
- Bump **minor**: Include `(MINOR)` in commit message
- Bump **patch**: Default for all other commits

Example:

```bash
git commit -m "feat: add feature (MINOR)"
git commit -m "fix: resolve bug"
git commit -m "breaking: redesign API (MAJOR)"
```

## GitHub Secrets Required

**Repository Secrets**:

- `AZURE_CLIENT_ID` - Service Principal Client ID
- `AZURE_TENANT_ID` - Azure AD Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `ACR_NAME` - Azure Container Registry name (e.g., `terracloudacr`)
- `INFRA_REPO_PAT` - (Optional) GitHub PAT for triggering deployments

**Variables:**

- `INFRA_REPO` - (Optional) e.g., `username/terra_cloud_infra`

## Local Development

```bash
cd app
composer install
cp .env.example .env
php artisan key:generate
php artisan test
```

For infrastructure, see **terra_cloud_infra** repository..
