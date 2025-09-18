# Terragrunt Azure Deployment Guide

This guide outlines the steps required to deploy the containerized Laravel application to Azure using the provided Terragrunt configuration.

### Prerequisites

Make sure you have the following command-line tools installed:
*   [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
*   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
*   [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)

---

### Step 1: Log in to Azure

Open your terminal and run the following command. Follow the prompts in your browser to authenticate with your Azure account.

```bash
az login
```

---

### Step 2: Create Backend Storage for Terraform State

Terragrunt and Terraform need an Azure Storage Account to store the state of your infrastructure. This is crucial for collaboration and state management.

First, set some variables in your shell. The storage account name must be globally unique, so a random suffix is added.

```bash
export RESOURCE_GROUP_NAME="tfstate-rg"
export STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"
export LOCATION="EastUS"

# Create the resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create the storage account
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Standard_LRS

# Create the blob container for storing state files
az storage container create --name tfstate --account-name $STORAGE_ACCOUNT_NAME
```

Next, **update the root `terragrunt/terragrunt.hcl` file** with the `resource_group_name` and `storage_account_name` you just created. Replace the `"PLEASE_UPDATE"` placeholders.

---

### Step 3: Configure Your Environment Variables

1.  Navigate to the `dev` environment directory:
    ```bash
    cd terragrunt/dev
    ```

2.  Copy the example variables file to create your own local configuration:
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

3.  **Generate a new Laravel App Key**. Run this command from the root of your project and copy the `base64:...` output:
    ```bash
    php artisan key:generate --show
    ```

4.  **Edit `terraform.tfvars`**. Open this new file and:
    *   Paste the generated app key as the value for `APP_KEY`.
    *   Update the `APP_URL` to match the app name that will be created (e.g., `https://sampleapp-dev-app.azurewebsites.net`).

---

### Step 4: Build and Push Your Docker Image

This step is a two-part process. First, you create the Azure Container Registry (ACR) with Terragrunt, then you push your Docker image to it.

1.  **Initialize Terragrunt**. From the `terragrunt/dev` directory, run:
    ```bash
    terragrunt init
    ```
    This downloads the necessary Terraform providers and configures the remote state backend you created in Step 2.

2.  **First Apply**. Run `apply` to create the initial set of resources, which includes the ACR.
    ```bash
    terragrunt apply
    ```
    Review the plan shown by Terragrunt and, when prompted, type `yes` to approve it. Make a note of the `azurerm_container_registry` name in the output (e.g., `sampleappdevacr`).

3.  **Build and Push the Image**. Go back to the project root directory. Use the Azure CLI to build your `Dockerfile` and push the resulting image directly to your new ACR.

    ```bash
    cd ../..
    az acr build --registry <your-acr-name> --image sample-app:latest .
    ```
    (Replace `<your-acr-name>` with the actual ACR name from the previous step).

---

### Step 5: Update Image Name and Final Deployment

1.  The Terraform module needs the full, correct path to your image in the registry. **Update `terragrunt/dev/terragrunt.hcl`**. Change the `docker_image` input to use the login server of your new ACR.

    *Before:*
    ```hcl
    docker_image = "sampleapp.azurecr.io/sample-app"
    ```

    *After (example):*
    ```hcl
    docker_image = "sampleappdevacr.azurecr.io/sample-app"
    ```

2.  **Final Apply**. Go back to the `dev` directory and run `apply` one last time.
    ```bash
    cd terragrunt/dev
    terragrunt apply
    ```
    This final run will update the App Service to point to your container image, completing the deployment.

Your application should now be deployed and accessible at the URL provided in the Terraform outputs.

---

### Clean Up

To destroy all the Azure resources created by this process and avoid further charges, run the destroy command from the `terragrunt/dev` directory:

```bash
terragrunt destroy
```
