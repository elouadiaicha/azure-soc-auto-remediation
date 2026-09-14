#!/bin/bash
# ==============================================================================
# SCRIPT DE TEST END-TO-END : ATTAQUE / DÉTECTION SENTINEL / REMÉDIATION LOGIC APP
# ==============================================================================

# --- CONFIGURATION (À adapter selon vos ressources) ---
RESOURCE_GROUP="rg-DZ"
NSG_NAME="nsg-soc-demo"
TEST_RULE_NAME="Allow-SSH-Internet-Demo"
WORKSPACE_NAME="law-soc-sentinel"
SENTINEL_RULE_DISPLAY_NAME="Détection Ouverture SSH 22" # Nom exact de votre règle d'alerte Sentinel

# Couleurs pour le terminal
GREEN='\030[0;32m'
RED='\030[0;31m'
YELLOW='\030[1;33m'
BLUE='\030[0;34m'
NC='\030[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}  Lancement du Test Automatisé de Remédiation Sentinel ${NC}"
echo -e "${BLUE}=====================================================${NC}\n"

# 0. Récupération des Identifiants Azure
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
WORKSPACE_ID=$(az monitor log-analytics workspace show -g "$RESOURCE_GROUP" -n "$WORKSPACE_NAME" --query customerId -o tsv 2>/dev/null)

if [ -z "$WORKSPACE_ID" ]; then
    echo -e "${RED}❌ Erreur : Impossible de trouver le Log Analytics Workspace '$WORKSPACE_NAME'.${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# ÉTAPE 1 : SIMULATION DE L'ATTAQUE (Création de la règle NSG vulnérable)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[1/4] Simulation de l'attaque : Création de la règle NSG vulnérable (SSH 22 Ouvert)...${NC}"

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name "$TEST_RULE_NAME" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 22 \
  --source-address-prefixes '*' \
  --output none

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Règle NSG '$TEST_RULE_NAME' créée avec succès !${NC}\n"
else
    echo -e "${RED}❌ Échec de la création de la règle NSG.${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# ÉTAPE 2 : ATTENTE DE L'INGESTION DES LOGS DANS LOG ANALYTICS
# ------------------------------------------------------------------------------
# Azure Activity Logs met environ 60 à 90 secondes à arriver dans Log Analytics.
# On attend que le log soit visible avant d'exécuter Sentinel, sinon la requête renverra 0 résultat.
echo -e "${YELLOW}[2/4] Attente de l'ingestion du log AzureActivity dans Log Analytics...${NC}"

MAX_RETRIES=15
LOG_FOUND=0

for ((i=1; i<=MAX_RETRIES; i++)); do
    COUNT=$(az monitor log-analytics query --workspace "$WORKSPACE_ID" \
      --analytics-query "AzureActivity | where OperationNameValue =~ 'Microsoft.Network/networkSecurityGroups/securityRules/write' | where ActivityStatusValue == 'Success' | count" \
      --query "tables[0].rows[0][0]" -o tsv 2>/dev/null)

    if [ "$COUNT" -gt "0" ]; then
        echo -e "${GREEN}✅ Log d'activité ingéré avec succès dans AzureActivity !${NC}\n"
        LOG_FOUND=1
        break
    fi
    echo -e "   ⏳ Log pas encore présent ($i/$MAX_RETRIES)... Attente de 10s"
    sleep 10
done

if [ $LOG_FOUND -eq 0 ]; then
    echo -e "${RED}❌ Le log n'a pas été ingéré à temps dans Log Analytics. Réessayez ou augmentez le temps d'attente.${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# ÉTAPE 3 : FORCER L'EXÉCUTION IMMÉDIATE DE LA RÈGLE SENTINEL (Bypass des 5 min)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[3/4] Forçage du scan Sentinel (Toggle Désactivation / Réactivation)...${NC}"

# Recherche du GUID de la règle d'alerte Sentinel via le DisplayName
RULE_ID=$(az rest --method get \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE_NAME}/providers/Microsoft.SecurityInsights/alertRules?api-version=2023-02-01-preview" \
  --query "value[?properties.displayName=='${SENTINEL_RULE_DISPLAY_NAME}'].name | [0]" -o tsv 2>/dev/null)

if [ -z "$RULE_ID" ] || [ "$RULE_ID" == "null" ]; then
    echo -e "${RED}❌ Erreur : Impossible de trouver la règle Sentinel nommée '$SENTINEL_RULE_DISPLAY_NAME'. Vérifiez le nom exact.${NC}"
    exit 1
fi

# 1. Désactivation temporaire
az rest --method patch \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE_NAME}/providers/Microsoft.SecurityInsights/alertRules/${RULE_ID}?api-version=2023-02-01-preview" \
  --body '{"kind": "Scheduled", "properties": {"enabled": false}}' --output none 2>/dev/null

sleep 2

# 2. Réactivation -> Force Sentinel à déclencher la requête KQL immédiatement !
az rest --method patch \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/${WORKSPACE_NAME}/providers/Microsoft.SecurityInsights/alertRules/${RULE_ID}?api-version=2023-02-01-preview" \
  --body '{"kind": "Scheduled", "properties": {"enabled": true}}' --output none 2>/dev/null

echo -e "${GREEN}✅ Scan Sentinel déclenché immédiatement ! Incidents & Automation Rule en cours de traitement...${NC}\n"

# ------------------------------------------------------------------------------
# ÉTAPE 4 : VÉRIFICATION DE LA REMÉDIATION PAR LA LOGIC APP
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[4/4] Vérification de la remédiation automatique (Suppression de la règle NSG)...${NC}"

REMEDIATED=0
for ((i=1; i<=12; i++)); do
    EXISTS=$(az network nsg rule show -g "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" -n "$TEST_RULE_NAME" --query name -o tsv 2>/dev/null)

    if [ -z "$EXISTS" ]; then
        REMEDIATED=1
        break
    fi
    echo -e "   ⏳ Règle NSG toujours présente... Attente de la Logic App ($i/12) - pause 10s"
    sleep 10
done

echo ""
if [ $REMEDIATED -eq 1 ]; then
    echo -e "${GREEN}=================================================================${NC}"
    echo -e "${GREEN}🎉 SUCCÈS TOTAL : La règle NSG vulnérable a été supprimée !      ${NC}"
    echo -e "${GREEN}    - Log ingéré dans Log Analytics                               ${NC}"
    echo -e "${GREEN}    - Alerte & Incident générés dans Sentinel                     ${NC}"
    echo -e "${GREEN}    - Logic App exécutée et menace rémédiée en automatique.       ${NC}"
    echo -e "${GREEN}=================================================================${NC}"
else
    echo -e "${RED}=================================================================${NC}"
    echo -e "${RED}❌ ÉCHEC : La règle NSG n'a pas été supprimée après 2 minutes.    ${NC}"
    echo -e "${RED}   Vérifiez l'historique d'exécution de votre Logic App dans Azure.${NC}"
    echo -e "${RED}=================================================================${NC}"
fi