# Terragrunt Azure Deployment Guide

This guide outlines the steps required to deploy the containerized Laravel application and its database to Azure using the provided Terragrunt configuration.

This project is configured with two cloud environments:

- `qa`: A cost-effective environment for testing and quality assurance.
- `prod`: A more powerful, production-grade environment for the live application.

### Working with Environments (`qa` and `prod`)

All `terragrunt` commands must be run from within the directory of the environment you want to affect.

- To work with the **QA** environment, first change into its directory: `cd terragrunt/qa`
- To work with the **Production** environment, first change into its directory: `cd terragrunt/prod`

The rest of this guide assumes you are running commands from within your chosen environment directory.

### Prerequisites

Make sure you have the following command-line tools installed:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)

---

### Step 1: Log in to Azure

Open your terminal and run the following command. Follow the prompts in your browser to authenticate with your Azure account.

```bash
az login
```

---

### Step 2: Create Backend Storage for Terraform State

This is a **one-time setup**. Terragrunt needs an Azure Storage Account to store the state of your infrastructure, which is shared between all environments.

```bash
export RESOURCE_GROUP_NAME="tfstate-rg"
export STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"
export LOCATION="WestEurope"

# Create the resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create the storage account
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Standard_LRS

# Create the blob container for storing state files
az storage container create --name tfstate --account-name $STORAGE_ACCOUNT_NAME
```

Next, **update the root `terragrunt/terragrunt.hcl` file** with the `resource_group_name` and `storage_account_name` you just created. Replace the `"PLEASE_UPDATE"` placeholders.

---

### Step 3: Configure Your Environment Secrets

This step must be done for **each environment** you intend to deploy.

1.  Navigate to your chosen environment directory (e.g., `cd terragrunt/qa`).

2.  Copy the example variables file:

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

3.  **Edit the new `terraform.tfvars` file** and set the required secrets:
    - **`db_admin_password`**: Set a strong, complex password for the database administrator.
    - **`APP_KEY`**: From the **root of the project**, run `php artisan key:generate --show` and paste the full `base64:...` output here.
    - **`APP_URL`**: Update this with the future URL of your application (e.g., `https://sampleapp-qa-app.azurewebsites.net` for the QA environment).

---

### Step 4: Build and Push Your Docker Image

This step is a two-part process. First, you create the Azure resources, then you push your Docker image to the new container registry.

1.  **Initialize Terragrunt**. From your chosen environment directory, run:

    ```bash
    terragrunt init
    ```

2.  **First Apply**. Run `apply` to create the Azure resources for the current environment.

    ```bash
    terragrunt apply
    ```

    Review the plan and type `yes` to approve it. Make a note of the `azurerm_container_registry` name in the output (e.g., `sampleappqaacr` for QA).

3.  **Build and Push the Image**. Go back to the project root directory. Use the Azure CLI to build and push your image.
    ```bash
    cd ../..
    az acr build --registry <your-acr-name> --image sample-app:latest .
    ```
    (Replace `<your-acr-name>` with the name from the previous step).

---

### Step 5: Update Image Name and Final Deployment

1.  The Terraform module needs the full path to your image. **Update the `terragrunt.hcl` file in your environment directory** (e.g., `terragrunt/qa/terragrunt.hcl`). Change the `docker_image` input to use the login server of your new ACR.

    _After (example for QA):_

    ```hcl
    docker_image = "sampleappqaacr.azurecr.io/sample-app"
    ```

2.  **Final Apply**. Go back to your environment directory (e.g., `cd terragrunt/qa`) and run `apply` one last time.
    ```bash
    terragrunt apply
    ```
    This final run will update the App Service to point to your container image, completing the deployment.

---

### Clean Up

To destroy all the resources in a specific environment, navigate to its directory (e.g., `cd terragrunt/qa`) and run:

```bash
terragrunt destroy
```
