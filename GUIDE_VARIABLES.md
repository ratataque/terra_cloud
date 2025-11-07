# 🔐 Guide d'utilisation des variables

Ce guide explique comment utiliser le fichier `.env.terraform` pour configurer vos variables d'environnement.

## 🚀 Démarrage rapide

### 1. Charger les variables

```bash
# À la racine du projet
source .env.terraform
```

Vous verrez :
```
🔧 Chargement des variables TerraCloud IaaS...
✅ SSH_PUBLIC_KEY chargée
✅ DB_ADMIN_PASSWORD configuré
✅ TF_VAR_APP_KEY généré
✅ DOCKER_TAG: latest

✅ Toutes les variables sont chargées !
```

### 2. Déployer

```bash
cd terragrunt/iaas/qa
terragrunt init
terragrunt apply
```

---

## 📝 Variables disponibles

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `SSH_PUBLIC_KEY` | Clé SSH publique pour accéder aux VMs | Générée automatiquement |
| `DB_ADMIN_PASSWORD` | Mot de passe MySQL | `TerraCloud2024!` |
| `TF_VAR_APP_KEY` | Clé d'encryption Laravel | Générée aléatoirement |
| `DOCKER_TAG` | Tag de l'image Docker | `latest` |

---

## 🔧 Personnalisation

### Changer le mot de passe de la base de données

Éditez `.env.terraform` et modifiez la ligne :
```bash
export DB_ADMIN_PASSWORD="VotreNouveauMotDePasse123!"
```

### Utiliser une clé Laravel fixe

Générez une clé une fois :
```bash
openssl rand -base64 32
```

Puis dans `.env.terraform`, remplacez :
```bash
export TF_VAR_APP_KEY="base64:VOTRE_CLE_GENEREE"
```

### Changer le tag Docker

Avant de charger les variables :
```bash
export DOCKER_TAG="v1.0.0"
source .env.terraform
```

Ou modifiez directement dans `.env.terraform` :
```bash
export DOCKER_TAG="v1.0.0"
```

---

## ✅ Vérifier les variables

```bash
# Après avoir fait "source .env.terraform"

# Vérifier SSH_PUBLIC_KEY
echo $SSH_PUBLIC_KEY

# Vérifier DB_ADMIN_PASSWORD
echo $DB_ADMIN_PASSWORD

# Vérifier TF_VAR_APP_KEY
echo $TF_VAR_APP_KEY

# Vérifier DOCKER_TAG
echo $DOCKER_TAG
```

---

## 🔄 Workflow quotidien

### Nouveau terminal

À chaque fois que vous ouvrez un nouveau terminal :

```bash
# 1. Aller à la racine du projet
cd /Users/pwth/Documents/Epitech/terra_cloud

# 2. Charger les variables
source .env.terraform

# 3. Travailler normalement
cd terragrunt/iaas/qa
terragrunt plan
```

### Automatiser le chargement

Pour charger automatiquement les variables, ajoutez à votre `~/.zshrc` :

```bash
# Auto-load TerraCloud variables
if [ -f ~/Documents/Epitech/terra_cloud/.env.terraform ]; then
    alias terracloud="cd ~/Documents/Epitech/terra_cloud && source .env.terraform"
fi
```

Puis rechargez :
```bash
source ~/.zshrc
```

Maintenant, tapez juste `terracloud` pour aller au projet et charger les variables ! 🎉

---

## 🔐 Sécurité

### ⚠️ Important

- ✅ Le fichier `.env.terraform` est dans `.gitignore`
- ✅ Ne commitez JAMAIS ce fichier
- ✅ Ne partagez JAMAIS vos mots de passe
- ✅ Utilisez des mots de passe forts en production

### Clé SSH

Votre clé SSH privée est dans : `~/.ssh/terracloud_rsa`

**Pour vous connecter à une VM :**
```bash
ssh -i ~/.ssh/terracloud_rsa azureuser@<IP_VM>
```

### Sauvegarder vos variables

Pour ne pas perdre vos variables, sauvegardez `.env.terraform` dans un endroit sûr :
- Gestionnaire de mots de passe (1Password, Bitwarden, etc.)
- Coffre-fort chiffré
- Azure Key Vault (pour la production)

---

## 🐛 Dépannage

### "SSH_PUBLIC_KEY is empty"

```bash
# Vérifier que la clé existe
ls -la ~/.ssh/terracloud_rsa*

# Si elle n'existe pas, la générer
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terracloud_rsa -N ""

# Recharger les variables
source .env.terraform
```

### "Permission denied" lors du source

```bash
# Rendre le fichier exécutable
chmod +x .env.terraform

# Réessayer
source .env.terraform
```

### Variables non chargées

```bash
# Vérifier que vous êtes à la racine du projet
pwd
# Devrait afficher: /Users/pwth/Documents/Epitech/terra_cloud

# Vérifier que le fichier existe
ls -la .env.terraform

# Charger avec le chemin complet
source /Users/pwth/Documents/Epitech/terra_cloud/.env.terraform
```

---

## 📚 Ressources

- [IAAS_QUICKSTART.md](IAAS_QUICKSTART.md) - Guide de démarrage rapide
- [terragrunt/iaas/README.md](terragrunt/iaas/README.md) - Documentation IaaS complète
- [CHANGEMENTS_IAAS.md](CHANGEMENTS_IAAS.md) - Récapitulatif des changements
