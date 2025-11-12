# TerraCloud - Azure Deployment Guide

Complete infrastructure setup reflecting our actual implementation with Terragrunt, ACR webhooks, and automated CI/CD.

## Quick Summary

**What we built:**
- Shared ACR for Docker images  
- QA environment with App Service + MySQL
- GitHub Actions CI/CD with OIDC authentication
- ACR webhook for instant deployments (<30s)
- Automatic database migrations on container start

**Deploy time:** 3-4 minutes from code push to live

---

## Architecture

```
GitHub Push
    ↓
CI: Build Docker → Push to ACR  
    ↓
ACR Webhook triggers App Service
    ↓
App Service pulls :latest
    ↓  
Container starts → Migrations run → Apache starts
    ↓
✅ Live in 3-4 minutes
```

---

## Prerequisites

**Tools:**
- Azure CLI
- Terraform 1.5.7+
- Terragrunt 0.54.0+

**Azure:**
- Subscription with Contributor role OR
- Owner on existing resource group (`rg-stg_1`)

---

## Setup Steps

### 1. Azure Service Principal (OIDC)

```bash
SUBSCRIPTION_ID="your-sub-id"
GITHUB_ORG="your-username"
GITHUB_REPO="terra_cloud"

# Create app
APP_ID=$(az ad app create --display-name "TerraCloud-GitHub-OIDC" --query appId -o tsv)
az ad sp create --id $APP_ID
SP_ID=$(az ad sp list --display-name "TerraCloud-GitHub-OIDC" --query "[0].id" -o tsv)

# Grant permissions
az role assignment create --assignee $SP_ID --role Contributor \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# OIDC federation
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "GitHub-Main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

TENANT_ID=$(az account show --query tenantId -o tsv)
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"  
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

### 2. GitHub Secrets

**Repository secrets:**
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

**Environment "qa" secret:**
- `TF_VAR_APP_KEY` (generate with `php artisan key:generate --show`)

### 3. MySQL SSL Configuration

After first deploy:
```bash
az mysql flexible-server parameter set \
  --resource-group rg-stg_1 \
  --server-name terracloud-qa-mysql \
  --name require_secure_transport \
  --value OFF
```

### 4. Fix ACR Webhook (Important!)

The webhook needs URL-encoded credentials:
```bash
WEBHOOK_URL=$(az webapp deployment container show-cd-url \
  --name terracloud-qa-app --resource-group rg-stg_1 --query 'CI_CD_URL' -o tsv)
ENCODED_URL=$(echo "$WEBHOOK_URL" | sed 's/\$/%24/g')

az acr webhook update --name terracloudqahook \
  --registry terracloudsharedacr --resource-group rg-stg_1 --uri "$ENCODED_URL"
```

---

## Infrastructure Components

**Shared** (`terragrunt/shared/`):
- ACR (Standard SKU)

**QA** (`terragrunt/qa/`):
- App Service Plan B1
- Linux Web App (Docker)
- MySQL Flexible Server B_Standard_B1ms
- Database terracloud_qa
- ACR Webhook
- Managed Identity with AcrPull

---

## CI/CD Workflows

### CI (`.github/workflows/ci.yml`)
- **Trigger:** Push to main (non-terragrunt files)
- **Does:** Build Docker → Push to ACR
- **Tags:** `app:latest`, `app:<sha>`

### CD (`.github/workflows/terraform-cd.yml`)
- **Trigger:** Push to main (`terragrunt/**` files) or manual
- **Does:** Terragrunt plan → apply

---

## Auto-Deployment

**Two mechanisms:**

1. **ACR Webhook** (instant):
   - ACR calls App Service on push
   - App pulls new image
   - ~30 seconds

2. **Polling** (fallback):
   - `DOCKER_ENABLE_CI=true` 
   - Polls every 5-10 min
   - Azure-managed

---

## Environment Variables

Auto-configured by Terraform:
```
DOCKER_ENABLE_CI=true
DB_CONNECTION=mysql
DB_HOST=terracloud-qa-mysql.mysql.database.azure.com
DB_PORT=3306
DB_DATABASE=terracloud_qa
DB_USERNAME=dbadmin
DB_PASSWORD=<terraform>
APP_KEY=<github-secret>
```

---

## Monitoring

```bash
# Logs
az webapp log download --name terracloud-qa-app \
  --resource-group rg-stg_1 --log-file logs.zip

# Webhook events
az acr webhook list-events --name terracloudqahook \
  --registry terracloudsharedacr --resource-group rg-stg_1 -o table

# MySQL status
az mysql flexible-server show --resource-group rg-stg_1 \
  --name terracloud-qa-mysql --query "{name:name, state:state}"
```

---

## Troubleshooting

### Webhook 401 Error
**Fix:** URL-encode `$` character (see Setup Step 4)

### App 500 Error
**Check:** APP_KEY is set properly
```bash
az webapp config appsettings list --name terracloud-qa-app \
  --resource-group rg-stg_1 --query "[?name=='APP_KEY']"
```

### MySQL Timeout
**Fix:** Start server
```bash
az mysql flexible-server start --resource-group rg-stg_1 \
  --name terracloud-qa-mysql
```

### Container Not Updating
**Fix:** Manual restart
```bash
az webapp restart --name terracloud-qa-app --resource-group rg-stg_1
```

---

## Cost (~€30-50/month)
- App Service B1: €12
- MySQL B1ms: €15-25  
- ACR Standard: €5
- Other: €5

**Tip:** Stop MySQL when unused:
```bash
az mysql flexible-server stop --resource-group rg-stg_1 \
  --name terracloud-qa-mysql
```

---

## Resources

- [Terragrunt Docs](https://terragrunt.gruntwork.io/)
- [Azure App Service Containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [ACR Webhooks](https://learn.microsoft.com/azure/container-registry/container-registry-webhook)
- [GitHub OIDC Azure](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)


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
