# TerraCloud IaaS Deployment

Ce dossier contient les configurations Terragrunt pour déployer TerraCloud en mode **IaaS (Infrastructure as a Service)** sur Azure avec des machines virtuelles.

## 📋 Différence PaaS vs IaaS

### PaaS (Platform as a Service)
- ✅ Azure gère l'infrastructure
- ✅ Déploiement simplifié
- ❌ Moins de contrôle
- ❌ Généralement plus cher

### IaaS (Infrastructure as a Service) - **Ce dossier**
- ✅ Contrôle total sur les VMs
- ✅ Plus flexible et personnalisable
- ✅ Potentiellement moins cher
- ❌ Plus de responsabilités de gestion

## 🏗️ Architecture IaaS

```
┌─────────────────────────────────────────┐
│         Load Balancer (IP publique)     │
└────────────┬────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼───┐      ┌────────┐
│  VM 0  │      │  VM 1  │  ... │  VM N  │
│ Docker │      │ Docker │      │ Docker │
└────────┘      └────────┘      └────────┘
    │                 │              │
    └─────────────────┴──────────────┘
                  │
         ┌────────▼─────────┐
         │  MySQL Database  │
         └──────────────────┘
```

### Composants créés :
- **Virtual Network (VNet)** : Réseau privé pour vos VMs
- **Subnet** : Sous-réseau pour les VMs d'application
- **Network Security Group (NSG)** : Pare-feu (ports 80, 443, 22)
- **Load Balancer** : Distribue le trafic entre les VMs
- **VMs Linux (Ubuntu 22.04)** : Exécutent votre application Docker
- **MySQL Flexible Server** : Base de données gérée

## 📦 Prérequis

### 1. Outils installés
```bash
# Azure CLI
brew install azure-cli

# Terraform
brew install terraform

# Terragrunt
brew install terragrunt
```

### 2. Générer une clé SSH

**Important** : Vous devez créer une clé SSH pour accéder aux VMs.

```bash
# Générer une nouvelle clé SSH
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com" -f ~/.ssh/terracloud_rsa

# Afficher la clé publique
cat ~/.ssh/terracloud_rsa.pub
```

**Copiez** le contenu de la clé publique (commence par `ssh-rsa AAAA...`).

### 3. Variables d'environnement

Créez un fichier `.env` ou exportez ces variables :

```bash
# Clé SSH (OBLIGATOIRE)
export SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... votre-cle-publique"

# Mot de passe base de données
export DB_ADMIN_PASSWORD="VotreMotDePasseSecurise123!"

# Clé Laravel
export TF_VAR_APP_KEY="base64:votre-cle-generee"

# Tag Docker (optionnel)
export DOCKER_TAG="latest"
```

## 🚀 Déploiement

### Environnement QA

```bash
# 1. Aller dans le dossier QA
cd terragrunt/iaas/qa

# 2. Définir les variables
export SSH_PUBLIC_KEY="ssh-rsa AAAA..."
export DB_ADMIN_PASSWORD="SecurePass123!"
export TF_VAR_APP_KEY="base64:..."

# 3. Initialiser Terragrunt
terragrunt init

# 4. Planifier les changements
terragrunt plan

# 5. Déployer l'infrastructure
terragrunt apply
```

### Environnement Production

```bash
cd terragrunt/iaas/prod

# Même processus avec des variables de production
export SSH_PUBLIC_KEY="ssh-rsa AAAA..."
export DB_ADMIN_PASSWORD="ProductionPass123!"
export DOCKER_TAG="stable"

terragrunt init
terragrunt plan
terragrunt apply
```

## 📊 Après le déploiement

### Récupérer l'IP publique

```bash
# Afficher les outputs
terragrunt output

# Récupérer l'IP du Load Balancer
terragrunt output -raw load_balancer_public_ip
```

### Tester l'application

```bash
# Récupérer l'URL
APP_URL=$(terragrunt output -raw load_balancer_url)

# Tester
curl $APP_URL
```

### Se connecter à une VM

```bash
# Récupérer le nom d'une VM
VM_NAME=$(terragrunt output -json vm_names | jq -r '.[0]')

# Se connecter via SSH
ssh -i ~/.ssh/terracloud_rsa azureuser@<IP_PUBLIQUE_LB>

# Ou via Azure CLI
az vm run-command invoke \
  --resource-group rg-stg_1 \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "docker ps"
```

### Vérifier les logs Docker

```bash
# Se connecter à une VM
ssh -i ~/.ssh/terracloud_rsa azureuser@<VM_IP>

# Voir les conteneurs
docker ps

# Voir les logs de l'application
docker logs terracloud-app

# Suivre les logs en temps réel
docker logs -f terracloud-app
```

## 🔧 Gestion

### Mettre à jour l'application

```bash
# 1. Construire et pousser une nouvelle image Docker
cd ../../..  # Retour à la racine
az acr build --registry <ACR_NAME> --image app:v1.0.1 .

# 2. Mettre à jour le tag
export DOCKER_TAG="v1.0.1"

# 3. Redéployer
cd terragrunt/iaas/qa
terragrunt apply

# Les VMs vont automatiquement tirer la nouvelle image
```

### Scaler les VMs

Modifiez `vm_count` dans `terragrunt.hcl` :

```hcl
vm_count = 3  # Passer de 2 à 3 VMs
```

Puis :
```bash
terragrunt apply
```

### Redémarrer une VM

```bash
az vm restart \
  --resource-group rg-stg_1 \
  --name terracloud-qa-vm-0
```

## 🔍 Dépannage

### Les VMs ne démarrent pas

```bash
# Vérifier les logs de démarrage
az vm boot-diagnostics get-boot-log \
  --resource-group rg-stg_1 \
  --name terracloud-qa-vm-0
```

### L'application n'est pas accessible

```bash
# 1. Vérifier le Load Balancer
az network lb show \
  --resource-group rg-stg_1 \
  --name terracloud-qa-lb

# 2. Vérifier les règles NSG
az network nsg rule list \
  --resource-group rg-stg_1 \
  --nsg-name terracloud-qa-nsg \
  --output table

# 3. Se connecter à une VM et vérifier Docker
ssh -i ~/.ssh/terracloud_rsa azureuser@<VM_IP>
docker ps
docker logs terracloud-app
```

### Erreur de connexion SSH

```bash
# Vérifier que votre clé SSH est correcte
ssh-keygen -lf ~/.ssh/terracloud_rsa.pub

# Vérifier les permissions
chmod 600 ~/.ssh/terracloud_rsa
chmod 644 ~/.ssh/terracloud_rsa.pub
```

## 💰 Coûts estimés

### QA (2 VMs Standard_B2s)
- VMs : ~60€/mois
- Load Balancer : ~20€/mois
- MySQL B1ms : ~15€/mois
- **Total : ~95€/mois**

### Production (3 VMs Standard_D2s_v3)
- VMs : ~240€/mois
- Load Balancer : ~20€/mois
- MySQL GP_Standard_D2ds_v4 : ~150€/mois
- **Total : ~410€/mois**

## 🗑️ Nettoyage

Pour supprimer toute l'infrastructure :

```bash
cd terragrunt/iaas/qa
terragrunt destroy
```

⚠️ **Attention** : Cette action est irréversible !

## 📚 Ressources

- [Documentation Azure VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/)
- [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [Cloud-init](https://cloudinit.readthedocs.io/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
