#!/bin/bash
# Script de test pour vérifier que toutes les variables sont correctement configurées

echo "🧪 Test des variables TerraCloud IaaS"
echo "======================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
PASSED=0
FAILED=0

# Fonction de test
test_var() {
    local var_name=$1
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ]; then
        echo -e "${RED}❌ $var_name${NC} - Variable non définie"
        ((FAILED++))
        return 1
    else
        echo -e "${GREEN}✅ $var_name${NC} - OK"
        ((PASSED++))
        return 0
    fi
}

# Test 1: SSH_PUBLIC_KEY
echo "Test 1: SSH_PUBLIC_KEY"
if test_var "SSH_PUBLIC_KEY"; then
    if [[ $SSH_PUBLIC_KEY == ssh-rsa* ]] || [[ $SSH_PUBLIC_KEY == ssh-ed25519* ]]; then
        echo "   Format: OK (commence par ssh-rsa ou ssh-ed25519)"
    else
        echo -e "   ${YELLOW}⚠️  Format suspect (devrait commencer par ssh-rsa)${NC}"
    fi
    echo "   Longueur: $(echo $SSH_PUBLIC_KEY | wc -c) caractères"
fi
echo ""

# Test 2: DB_ADMIN_PASSWORD
echo "Test 2: DB_ADMIN_PASSWORD"
if test_var "DB_ADMIN_PASSWORD"; then
    local pass_length=${#DB_ADMIN_PASSWORD}
    if [ $pass_length -lt 8 ]; then
        echo -e "   ${YELLOW}⚠️  Mot de passe trop court (< 8 caractères)${NC}"
    else
        echo "   Longueur: $pass_length caractères (OK)"
    fi
    
    if [[ "$DB_ADMIN_PASSWORD" == "TerraCloud2024!" ]]; then
        echo -e "   ${YELLOW}⚠️  Vous utilisez le mot de passe par défaut${NC}"
        echo "   ${YELLOW}   Changez-le avant de déployer en production !${NC}"
    fi
fi
echo ""

# Test 3: TF_VAR_APP_KEY
echo "Test 3: TF_VAR_APP_KEY"
if test_var "TF_VAR_APP_KEY"; then
    if [[ $TF_VAR_APP_KEY == base64:* ]]; then
        echo "   Format: OK (commence par base64:)"
    else
        echo -e "   ${YELLOW}⚠️  Format incorrect (devrait commencer par base64:)${NC}"
    fi
    echo "   Longueur: $(echo $TF_VAR_APP_KEY | wc -c) caractères"
fi
echo ""

# Test 4: DOCKER_TAG
echo "Test 4: DOCKER_TAG"
if test_var "DOCKER_TAG"; then
    echo "   Valeur: $DOCKER_TAG"
fi
echo ""

# Test 5: Clé SSH privée
echo "Test 5: Clé SSH privée"
if [ -f ~/.ssh/terracloud_rsa ]; then
    echo -e "${GREEN}✅ Clé privée${NC} - Existe (~/.ssh/terracloud_rsa)"
    ((PASSED++))
    
    # Vérifier les permissions
    local perms=$(stat -f "%OLp" ~/.ssh/terracloud_rsa 2>/dev/null || stat -c "%a" ~/.ssh/terracloud_rsa 2>/dev/null)
    if [ "$perms" = "600" ]; then
        echo "   Permissions: 600 (OK)"
    else
        echo -e "   ${YELLOW}⚠️  Permissions: $perms (devrait être 600)${NC}"
        echo "   Exécutez: chmod 600 ~/.ssh/terracloud_rsa"
    fi
else
    echo -e "${RED}❌ Clé privée${NC} - N'existe pas"
    echo "   Exécutez: ssh-keygen -t rsa -b 4096 -f ~/.ssh/terracloud_rsa"
    ((FAILED++))
fi
echo ""

# Test 6: Clé SSH publique
echo "Test 6: Clé SSH publique"
if [ -f ~/.ssh/terracloud_rsa.pub ]; then
    echo -e "${GREEN}✅ Clé publique${NC} - Existe (~/.ssh/terracloud_rsa.pub)"
    ((PASSED++))
else
    echo -e "${RED}❌ Clé publique${NC} - N'existe pas"
    ((FAILED++))
fi
echo ""

# Test 7: Fichier .env.terraform
echo "Test 7: Fichier .env.terraform"
if [ -f .env.terraform ]; then
    echo -e "${GREEN}✅ .env.terraform${NC} - Existe"
    ((PASSED++))
    
    # Vérifier qu'il est exécutable
    if [ -x .env.terraform ]; then
        echo "   Exécutable: Oui"
    else
        echo -e "   ${YELLOW}⚠️  Non exécutable${NC}"
        echo "   Exécutez: chmod +x .env.terraform"
    fi
else
    echo -e "${RED}❌ .env.terraform${NC} - N'existe pas"
    ((FAILED++))
fi
echo ""

# Test 8: .gitignore
echo "Test 8: .gitignore"
if [ -f .gitignore ]; then
    if grep -q ".env.terraform" .gitignore; then
        echo -e "${GREEN}✅ .gitignore${NC} - .env.terraform est ignoré"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  .gitignore${NC} - .env.terraform n'est pas ignoré"
        echo "   Ajoutez: echo '.env.terraform' >> .gitignore"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  .gitignore${NC} - N'existe pas"
    ((FAILED++))
fi
echo ""

# Résumé
echo "======================================"
echo "📊 Résumé des tests"
echo "======================================"
echo -e "${GREEN}✅ Tests réussis: $PASSED${NC}"
echo -e "${RED}❌ Tests échoués: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Tous les tests sont passés !${NC}"
    echo ""
    echo "Vous pouvez maintenant déployer :"
    echo "  cd terragrunt/iaas/qa"
    echo "  terragrunt init"
    echo "  terragrunt apply"
    exit 0
else
    echo -e "${RED}⚠️  Certains tests ont échoué${NC}"
    echo ""
    echo "Corrigez les erreurs ci-dessus avant de déployer."
    echo "Pour charger les variables : source .env.terraform"
    exit 1
fi
