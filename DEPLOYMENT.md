# TerraCloud Deployment Guide

Complete workflow guide for deploying the TerraCloud application to Azure using Terragrunt and Terraform.

## Overview

This guide covers the complete deployment workflow:
1. Azure authentication and state backend setup
2. Environment configuration with Terragrunt
3. Infrastructure provisioning with Terraform
4. Application deployment via Docker containers
5. Database migrations and application initialization

## Architecture

```
terragrunt/
├── terragrunt.hcl          # Root config with Azure backend
├── modules/
│   └── azure-app-service/  # Terraform module
├── qa/                     # QA environment
│   └── terragrunt.hcl
└── prod/                   # Production environment
    └── terragrunt.hcl
```

Each environment deploys:
- Resource Group
- Container Registry (ACR)
- MySQL Flexible Server
- App Service Plan
- Linux Web App (containerized)

---

## Prerequisites

Install required tools:

```bash
# Azure CLI
brew install azure-cli  # macOS
# or visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Terraform
brew install terraform  # macOS
# or visit: https://developer.hashicorp.com/terraform/install

# Terragrunt
brew install terragrunt  # macOS
# or visit: https://terragrunt.gruntwork.io/docs/getting-started/install/
```

---

## Step 1: Azure Authentication

Authenticate with Azure CLI:

```bash
az login
```

Set your subscription (if you have multiple):

```bash
az account list --output table
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

---

## Step 2: Create Terraform State Backend

**One-time setup** - creates shared storage for Terraform state files.

> 📖 **For production setup with versioning, geo-redundancy, and security**, see [STATE_BACKEND_SETUP.md](terragrunt/STATE_BACKEND_SETUP.md)

### Quick Setup (Development)

```bash
# Define variables
export TF_STATE_RG="terracloud-tfstate-rg"
export TF_STATE_SA="terracloudtfstate$(openssl rand -hex 2)"
export LOCATION="westeurope"

# Create resource group
az group create \
  --name $TF_STATE_RG \
  --location $LOCATION

# Create storage account
az storage account create \
  --name $TF_STATE_SA \
  --resource-group $TF_STATE_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --https-only true \
  --min-tls-version TLS1_2

# Create container
az storage container create \
  --name tfstate \
  --account-name $TF_STATE_SA \
  --auth-mode login

# Save these values
echo "TF_STATE_RG=$TF_STATE_RG"
echo "TF_STATE_SA=$TF_STATE_SA"
```

Export these variables (add to your `.bashrc` or `.zshrc`):

```bash
export TF_STATE_RG="terracloud-tfstate-rg"
export TF_STATE_SA="your-storage-account-name"
```

### Production Setup (Recommended)

For production, use geo-redundant storage with versioning:

```bash
# Use Standard_GRS instead of Standard_LRS
az storage account create \
  --name $TF_STATE_SA \
  --resource-group $TF_STATE_RG \
  --location $LOCATION \
  --sku Standard_GRS \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Enable versioning
az storage account blob-service-properties update \
  --account-name $TF_STATE_SA \
  --enable-versioning true

# Enable soft delete (30 days)
az storage account blob-service-properties update \
  --account-name $TF_STATE_SA \
  --enable-delete-retention true \
  --delete-retention-days 30
```

---

## Step 3: Environment Configuration

### For QA Environment

```bash
cd terragrunt/qa
```

Set required environment variables:

```bash
# Database password (use a strong password)
export DB_ADMIN_PASSWORD="YourSecurePassword123!"

# Laravel app key (generate with: php artisan key:generate --show)
export APP_KEY="base64:your-generated-key-here"

# Optional: Override Docker tag
export DOCKER_TAG="latest"
```

### For Production Environment

```bash
cd terragrunt/prod
```

Set production environment variables:

```bash
export DB_ADMIN_PASSWORD="YourProductionPassword123!"
export APP_KEY="base64:your-production-key-here"
export DOCKER_TAG="stable"
```

---

## Step 4: Infrastructure Deployment

### Initialize Terragrunt

```bash
terragrunt init
```

This will:
- Download Terraform providers
- Generate backend configuration
- Initialize the module

### Plan Infrastructure

Review changes before applying:

```bash
terragrunt plan
```

### Deploy Infrastructure

```bash
terragrunt apply
```

Type `yes` when prompted. This creates:
- Resource Group
- Container Registry
- MySQL Server & Database
- App Service Plan
- Web App

**Note the outputs**, especially:
- `acr_login_server`: e.g., `terracloudqaacr.azurecr.io`
- `app_service_url`: Your application URL

---

## Step 5: Build and Push Docker Image

### Authenticate to ACR

```bash
# Get ACR name from Terragrunt output
ACR_NAME=$(terragrunt output -raw acr_login_server | cut -d'.' -f1)

# Login to ACR
az acr login --name $ACR_NAME
```

### Build and Push Image

From the project root:

```bash
cd ../..  # Go to project root

# Build and push in one command
az acr build \
  --registry $ACR_NAME \
  --image app:latest \
  --file Dockerfile \
  .
```

Or build locally and push:

```bash
docker build -t $ACR_NAME.azurecr.io/app:latest .
docker push $ACR_NAME.azurecr.io/app:latest
```

---

## Step 6: Deploy Application

The Web App will automatically pull the Docker image. Wait a few minutes, then verify:

```bash
# Get app URL
APP_URL=$(terragrunt output -raw app_service_url)
echo "Application URL: $APP_URL"

# Test the application
curl -I $APP_URL
```

### Run Database Migrations

Connect to the App Service and run migrations:

```bash
# Get app name
APP_NAME=$(terragrunt output -raw app_service_name)

# SSH into the container
az webapp ssh --name $APP_NAME --resource-group terracloud-qa-rg

# Inside the container, run:
php artisan migrate --force
php artisan db:seed --force  # if you have seeders
```

Or use Azure CLI command execution:

```bash
az webapp ssh --name $APP_NAME \
  --resource-group terracloud-qa-rg \
  --command "php artisan migrate --force"
```

---

## Step 7: Verification

### Check Application Logs

```bash
az webapp log tail \
  --name $APP_NAME \
  --resource-group terracloud-qa-rg
```

### Test Endpoints

```bash
# Health check
curl $APP_URL/api/health

# Application
open $APP_URL  # macOS
```

---

## Workflow Summary

### Initial Deployment

```bash
# 1. Navigate to environment
cd terragrunt/qa

# 2. Set environment variables
export DB_ADMIN_PASSWORD="..." APP_KEY="..."

# 3. Deploy infrastructure
terragrunt init
terragrunt apply

# 4. Build and push image
cd ../..
az acr login --name terracloudqaacr
az acr build --registry terracloudqaacr --image app:latest .

# 5. Verify deployment
curl -I https://terracloud-qa-app.azurewebsites.net
```

### Update Application

```bash
# 1. Build new image with tag
az acr build --registry terracloudqaacr --image app:v1.2.3 .

# 2. Update environment config
cd terragrunt/qa
export DOCKER_TAG="v1.2.3"

# 3. Apply changes
terragrunt apply

# 4. Verify
az webapp restart --name terracloud-qa-app --resource-group terracloud-qa-rg
```

### Update Infrastructure

```bash
# 1. Modify terragrunt.hcl or module files
# 2. Plan changes
terragrunt plan

# 3. Apply changes
terragrunt apply
```

---

## Environment Management

### Switch Between Environments

```bash
# Work on QA
cd terragrunt/qa
terragrunt plan

# Work on Production
cd terragrunt/prod
terragrunt plan
```

### Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DB_ADMIN_PASSWORD` | Yes | MySQL admin password | `SecurePass123!` |
| `APP_KEY` | Yes | Laravel encryption key | `base64:xxx...` |
| `TF_STATE_RG` | Optional | Terraform state RG | `terracloud-tfstate-rg` |
| `TF_STATE_SA` | Optional | Terraform state SA | `terracloudtfstate` |
| `DOCKER_TAG` | Optional | Docker image tag | `latest`, `v1.0.0` |
| `AZURE_REGION` | Optional | Azure region | `westeurope` |

---

## Troubleshooting

### Issue: "Backend initialization required"

```bash
rm -rf .terraform .terragrunt-cache
terragrunt init
```

### Issue: "Container fails to start"

Check logs:
```bash
az webapp log tail --name terracloud-qa-app --resource-group terracloud-qa-rg
```

Restart the app:
```bash
az webapp restart --name terracloud-qa-app --resource-group terracloud-qa-rg
```

### Issue: "Cannot connect to database"

Verify firewall rules and connection string in app settings:
```bash
az webapp config appsettings list \
  --name terracloud-qa-app \
  --resource-group terracloud-qa-rg \
  --query "[?name=='DB_HOST'].value" -o tsv
```

### Issue: "ACR authentication failed"

Re-authenticate:
```bash
az acr login --name terracloudqaacr
```

---

## Cleanup

### Destroy Environment

```bash
cd terragrunt/qa
terragrunt destroy
```

Type `yes` to confirm. This removes all resources.

### Destroy State Backend (optional)

```bash
az group delete --name terracloud-tfstate-rg --yes --no-wait
```

---

## Best Practices

1. **Separate Environments**: Always work in the correct environment directory
2. **Version Control**: Commit infrastructure changes to Git
3. **Secrets Management**: Never commit secrets, use environment variables
4. **Image Tags**: Use semantic versioning for production images
5. **Plan Before Apply**: Always run `terragrunt plan` first
6. **State Locking**: Terragrunt handles this automatically via Azure backend
7. **Rollback**: Keep previous image tags for quick rollback

---

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

env:
  ACR_NAME: terracloudprodacr
  
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and Push
        run: |
          az acr build --registry $ACR_NAME --image app:${{ github.sha }} .
      
      - name: Deploy Infrastructure
        working-directory: terragrunt/prod
        env:
          DB_ADMIN_PASSWORD: ${{ secrets.DB_ADMIN_PASSWORD }}
          APP_KEY: ${{ secrets.APP_KEY }}
          DOCKER_TAG: ${{ github.sha }}
        run: |
          terragrunt init
          terragrunt apply -auto-approve
```

---

## Additional Resources

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
