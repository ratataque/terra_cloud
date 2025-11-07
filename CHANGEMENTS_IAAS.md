# 📝 Récapitulatif des changements IaaS

Branche : `feature/iaas`

## ✅ Fichiers créés

### Module Terraform IaaS
- ✅ `terragrunt/modules/azure-iaas-app-service/main.tf` - Infrastructure complète (VNet, VMs, Load Balancer, MySQL)
- ✅ `terragrunt/modules/azure-iaas-app-service/variables.tf` - Variables du module
- ✅ `terragrunt/modules/azure-iaas-app-service/outputs.tf` - Outputs (IP publique, VMs, etc.)
- ✅ `terragrunt/modules/azure-iaas-app-service/cloud-init.yaml` - Script de configuration automatique des VMs

### Configurations Terragrunt
- ✅ `terragrunt/iaas/qa/terragrunt.hcl` - Configuration QA (2 VMs Standard_B2s)
- ✅ `terragrunt/iaas/prod/terragrunt.hcl` - Configuration Production (3 VMs Standard_D2s_v3)

### Documentation
- ✅ `IAAS_QUICKSTART.md` - Guide de démarrage rapide
- ✅ `terragrunt/iaas/README.md` - Documentation complète IaaS

## 🔧 Modifications principales

### 1. Module IaaS (`main.tf`)
Crée l'infrastructure suivante :
- **Virtual Network** (10.0.0.0/16)
- **Subnet** pour les VMs (10.0.1.0/24)
- **Network Security Group** (ports 80, 443, 22)
- **Load Balancer** avec IP publique
- **VMs Linux Ubuntu 22.04** (configurées automatiquement)
- **MySQL Flexible Server**

### 2. Configurations Terragrunt

#### QA (`iaas/qa/terragrunt.hcl`)
```hcl
vm_size  = "Standard_B2s"  # 2 vCPUs, 4 GB RAM
vm_count = 2                # 2 VMs
ssh_public_key = get_env("SSH_PUBLIC_KEY", "...")
```

#### Production (`iaas/prod/terragrunt.hcl`)
```hcl
vm_size  = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM
vm_count = 3                  # 3 VMs
ssh_public_key = get_env("SSH_PUBLIC_KEY", "...")
```

### 3. Cloud-init (`cloud-init.yaml`)
Configure automatiquement chaque VM au démarrage :
- Installation de Docker, Docker Compose, Nginx
- Configuration de Nginx comme reverse proxy
- Login au Azure Container Registry
- Démarrage de l'application Docker
- Exécution des migrations de base de données

## 🚀 Pour déployer

```bash
# 1. Générer une clé SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terracloud_rsa

# 2. Exporter les variables
export SSH_PUBLIC_KEY="$(cat ~/.ssh/terracloud_rsa.pub)"
export DB_ADMIN_PASSWORD="VotreMotDePasse123!"
export TF_VAR_APP_KEY="base64:votre-cle"

# 3. Déployer
cd terragrunt/iaas/qa
terragrunt init
terragrunt apply
```

## 📊 Différences PaaS vs IaaS

| Composant | PaaS | IaaS |
|-----------|------|------|
| **Service principal** | Azure App Service | Azure VMs |
| **Configuration** | `app_service_plan_sku` | `vm_size` + `vm_count` |
| **Réseau** | Géré par Azure | VNet + Load Balancer |
| **Accès** | Portail Azure | SSH direct |
| **URL** | `*.azurewebsites.net` | IP publique du LB |
| **Coût QA** | ~150€/mois | ~95€/mois |

## 📦 Ressources créées par le module IaaS

### Réseau
- 1 Virtual Network
- 1 Subnet
- 1 Network Security Group
- 1 Public IP (Load Balancer)
- N Network Interfaces (une par VM)

### Compute
- 1 Load Balancer
- N Virtual Machines (2 en QA, 3 en Prod)

### Base de données
- 1 MySQL Flexible Server
- 1 MySQL Database

### Sécurité
- Règles NSG (HTTP, HTTPS, SSH)
- Règles firewall MySQL
- Identités managées pour les VMs

## 🎯 Prochaines étapes

1. **Tester le déploiement** en QA
2. **Valider l'accès SSH** aux VMs
3. **Vérifier l'application** via l'IP du Load Balancer
4. **Documenter les credentials** SSH et DB
5. **Créer un pipeline CI/CD** pour automatiser les déploiements

## 📚 Documentation

- Guide rapide : `IAAS_QUICKSTART.md`
- Documentation complète : `terragrunt/iaas/README.md`
- Déploiement PaaS : `DEPLOYMENT.md`
