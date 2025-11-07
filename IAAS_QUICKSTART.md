# 🚀 Guide de démarrage rapide - IaaS

Guide simplifié pour déployer TerraCloud en mode IaaS (avec des machines virtuelles).

## 🎯 En 5 minutes

### Étape 1 : Générer une clé SSH

```bash
# Créer une clé SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terracloud_rsa

# Afficher la clé publique (vous en aurez besoin)
cat ~/.ssh/terracloud_rsa.pub
```

**Copiez** tout le contenu qui s'affiche (commence par `ssh-rsa AAAA...`).

---

### Étape 2 : Configurer les variables

```bash
# Définir votre clé SSH (collez ce que vous avez copié)
export SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."

# Définir un mot de passe pour la base de données
export DB_ADMIN_PASSWORD="MonMotDePasse123!"

# Générer une clé Laravel (si vous ne l'avez pas)
export TF_VAR_APP_KEY="base64:$(openssl rand -base64 32)"
```

---

### Étape 3 : Se connecter à Azure

```bash
# Se connecter
az login

# Vérifier votre abonnement
az account show
```

---

### Étape 4 : Déployer l'infrastructure

```bash
# Aller dans le dossier IaaS QA
cd terragrunt/iaas/qa

# Initialiser
terragrunt init

# Déployer (tapez "yes" quand demandé)
terragrunt apply
```

⏱️ **Temps d'attente** : 10-15 minutes pour créer toute l'infrastructure.

---

### Étape 5 : Accéder à votre application

```bash
# Récupérer l'URL de votre application
terragrunt output load_balancer_url

# Tester
curl $(terragrunt output -raw load_balancer_url)
```

🎉 **C'est fait !** Votre application est accessible via l'URL affichée.

---

## 🔍 Commandes utiles

### Voir les informations de déploiement

```bash
# Voir tous les outputs
terragrunt output

# IP publique du Load Balancer
terragrunt output load_balancer_public_ip

# Noms des VMs
terragrunt output vm_names
```

### Se connecter à une VM

```bash
# Récupérer l'IP
LB_IP=$(terragrunt output -raw load_balancer_public_ip)

# Se connecter
ssh -i ~/.ssh/terracloud_rsa azureuser@$LB_IP
```

### Voir les logs de l'application

```bash
# Se connecter à une VM d'abord
ssh -i ~/.ssh/terracloud_rsa azureuser@<IP>

# Puis voir les logs
docker logs terracloud-app

# Suivre les logs en temps réel
docker logs -f terracloud-app
```

---

## 🛠️ Mettre à jour l'application

```bash
# 1. Construire une nouvelle image
cd ../../..  # Retour à la racine du projet
az acr build --registry <NOM_ACR> --image app:v1.0.1 .

# 2. Mettre à jour le tag
export DOCKER_TAG="v1.0.1"

# 3. Redéployer
cd terragrunt/iaas/qa
terragrunt apply
```

---

## 🗑️ Supprimer tout

```bash
cd terragrunt/iaas/qa
terragrunt destroy
```

⚠️ Tapez "yes" pour confirmer. **Tout sera supprimé !**

---

## ❓ Problèmes courants

### "Permission denied (publickey)"

Vérifiez que votre variable `SSH_PUBLIC_KEY` est bien définie :
```bash
echo $SSH_PUBLIC_KEY
```

### "Error: Invalid SSH public key"

Assurez-vous de copier **toute** la clé publique, y compris `ssh-rsa` au début.

### "Application not accessible"

Attendez 2-3 minutes après le déploiement. Les VMs ont besoin de temps pour démarrer Docker et télécharger l'image.

### "Database connection failed"

Vérifiez que `DB_ADMIN_PASSWORD` est défini et correspond à ce qui est dans la base de données.

---

## 📖 Documentation complète

Pour plus de détails, consultez :
- [`terragrunt/iaas/README.md`](terragrunt/iaas/README.md) - Documentation IaaS complète
- [`DEPLOYMENT.md`](DEPLOYMENT.md) - Guide de déploiement PaaS

---

## 💡 Différences PaaS vs IaaS

| Aspect | PaaS | IaaS (ce guide) |
|--------|------|-----------------|
| **Gestion** | Azure gère tout | Vous gérez les VMs |
| **Complexité** | Simple | Moyenne |
| **Coût QA** | ~150€/mois | ~95€/mois |
| **Contrôle** | Limité | Total |
| **SSH** | Non disponible | Accès direct |

---

## 🎓 Pour les débutants

### Qu'est-ce qu'une VM ?
Une **machine virtuelle** est comme un ordinateur virtuel dans le cloud. Vous pouvez vous y connecter, installer des logiciels, etc.

### Qu'est-ce qu'un Load Balancer ?
Un **répartiteur de charge** qui distribue le trafic entre plusieurs VMs pour :
- Améliorer les performances
- Assurer la haute disponibilité
- Si une VM tombe, les autres prennent le relais

### Qu'est-ce que cloud-init ?
Un script qui s'exécute **automatiquement** au premier démarrage de la VM pour :
- Installer Docker
- Configurer Nginx
- Démarrer votre application

### Qu'est-ce que SSH ?
**Secure Shell** - Un protocole pour se connecter de manière sécurisée à une machine distante via le terminal.

---

## 📞 Besoin d'aide ?

1. Consultez la section **Dépannage** dans [`terragrunt/iaas/README.md`](terragrunt/iaas/README.md)
2. Vérifiez les logs Azure : `az vm boot-diagnostics get-boot-log`
3. Connectez-vous à une VM et vérifiez Docker : `docker ps`

---

**Bon déploiement ! 🚀**
