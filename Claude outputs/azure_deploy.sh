#!/bin/bash

###############################################################################
# Azure Deployment Script for Know Modern ERP - Financial Planner
# This script provisions all necessary Azure resources
#
# Prerequisites:
#   - Azure CLI installed (az --version)
#   - Logged in (az login)
#   - jq installed for JSON parsing
#   - Sufficient permissions in Azure subscription
#
# Usage: bash azure_deploy.sh
###############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - UPDATE THESE VALUES
PROJECT_NAME="knowerp"
RESOURCE_GROUP="${PROJECT_NAME}-resources"
LOCATION="eastus"
APP_SERVICE_PLAN="${PROJECT_NAME}-plan"
APP_SERVICE="${PROJECT_NAME}-app"
POSTGRES_SERVER="${PROJECT_NAME}-db"
POSTGRES_DB="plannerhostingdb"
POSTGRES_ADMIN="planner_admin"
POSTGRES_PASSWORD="ChangeMe@$(date +%s)"  # Generate secure password
KEY_VAULT="${PROJECT_NAME}-vault"
TIER="B2"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Azure Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Step 1: Validate Azure CLI
print_info "Checking Azure CLI installation..."
if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Please install it from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
print_success "Azure CLI found: $(az --version | head -n1)"

# Step 2: Check if logged in
print_info "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_error "Not logged into Azure. Run 'az login' first."
    exit 1
fi

SUBSCRIPTION=$(az account show --query "id" -o tsv)
SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)
print_success "Logged in to subscription: $SUBSCRIPTION_NAME"

# Step 3: Confirm settings
echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "  Project Name:     $PROJECT_NAME"
echo "  Resource Group:   $RESOURCE_GROUP"
echo "  Location:         $LOCATION"
echo "  App Service Plan: $APP_SERVICE_PLAN"
echo "  App Service:      $APP_SERVICE"
echo "  PostgreSQL Server: $POSTGRES_SERVER"
echo "  Database Name:    $POSTGRES_DB"
echo "  DB Admin User:    $POSTGRES_ADMIN"
echo "  Key Vault:        $KEY_VAULT"
echo "  Tier:             $TIER"
echo ""
read -p "Continue with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled."
    exit 1
fi

# Step 4: Create Resource Group
print_info "Creating Resource Group: $RESOURCE_GROUP"
if az group exists --name "$RESOURCE_GROUP" --query 'value' -o tsv | grep -q "true"; then
    print_warning "Resource Group already exists"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    print_success "Resource Group created"
fi

# Step 5: Create App Service Plan
print_info "Creating App Service Plan: $APP_SERVICE_PLAN"
az appservice plan create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE_PLAN" \
    --sku "$TIER" \
    --is-linux \
    --number-of-workers 1
print_success "App Service Plan created"

# Step 6: Create App Service (Web App)
print_info "Creating App Service: $APP_SERVICE"
az webapp create \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN" \
    --name "$APP_SERVICE" \
    --runtime "node|20-lts"
print_success "App Service created"

# Step 7: Configure App Service Settings
print_info "Configuring App Service..."
az webapp config set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE" \
    --startup-file "npm start"

# Set app settings
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE" \
    --settings \
        NODE_ENV="production" \
        WEBSITE_NODE_DEFAULT_VERSION="20-lts"
print_success "App Service configured"

# Step 8: Create PostgreSQL Flexible Server
print_info "Creating PostgreSQL Flexible Server: $POSTGRES_SERVER"
print_warning "This may take 5-10 minutes..."

az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_SERVER" \
    --location "$LOCATION" \
    --admin-user "$POSTGRES_ADMIN" \
    --admin-password "$POSTGRES_PASSWORD" \
    --sku-name "Standard_B2s" \
    --tier "Burstable" \
    --storage-size 32 \
    --version 15 \
    --public-access "0.0.0.0" \
    --high-availability "Disabled" \
    --backup-retention 7

print_success "PostgreSQL Flexible Server created"

# Step 9: Create Database
print_info "Creating database: $POSTGRES_DB"
az postgres flexible-server db create \
    --resource-group "$RESOURCE_GROUP" \
    --server-name "$POSTGRES_SERVER" \
    --database-name "$POSTGRES_DB"
print_success "Database created"

# Step 10: Configure Firewall - Allow Azure Services
print_info "Configuring firewall to allow Azure services..."
az postgres flexible-server firewall-rule create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_SERVER" \
    --rule-name "AllowAzureServices" \
    --start-ip-address "0.0.0.0" \
    --end-ip-address "0.0.0.0"
print_success "Firewall rule created"

# Step 11: Configure PostgreSQL SSL requirement
print_info "Configuring PostgreSQL SSL requirement..."
az postgres flexible-server parameter set \
    --resource-group "$RESOURCE_GROUP" \
    --server-name "$POSTGRES_SERVER" \
    --name "require_secure_transport" \
    --value "ON"
print_success "SSL requirement configured"

# Step 12: Create Key Vault
print_info "Creating Key Vault: $KEY_VAULT"
az keyvault create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$KEY_VAULT" \
    --location "$LOCATION" \
    --enable-soft-delete true
print_success "Key Vault created"

# Step 13: Store Database Connection String in Key Vault
print_info "Storing database credentials in Key Vault..."
DB_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
DB_CONNECTION_STRING="postgresql://${POSTGRES_ADMIN}:${POSTGRES_PASSWORD}@${DB_HOST}:5432/${POSTGRES_DB}?sslmode=require"

az keyvault secret set \
    --vault-name "$KEY_VAULT" \
    --name "database-connection-string" \
    --value "$DB_CONNECTION_STRING"

az keyvault secret set \
    --vault-name "$KEY_VAULT" \
    --name "database-host" \
    --value "$DB_HOST"

az keyvault secret set \
    --vault-name "$KEY_VAULT" \
    --name "database-user" \
    --value "$POSTGRES_ADMIN"

az keyvault secret set \
    --vault-name "$KEY_VAULT" \
    --name "database-password" \
    --value "$POSTGRES_PASSWORD"

print_success "Credentials stored in Key Vault"

# Step 14: Grant App Service Access to Key Vault
print_info "Granting App Service access to Key Vault..."
IDENTITY=$(az webapp identity assign \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE" \
    --query principalId -o tsv)

az keyvault set-policy \
    --vault-name "$KEY_VAULT" \
    --object-id "$IDENTITY" \
    --secret-permissions get list
print_success "Key Vault access configured"

# Step 15: Create Application Insights
print_info "Creating Application Insights for monitoring..."
az monitor app-insights component create \
    --app "$APP_SERVICE-insights" \
    --location "$LOCATION" \
    --resource-group "$RESOURCE_GROUP" \
    --application-type web
print_success "Application Insights created"

# Step 16: Get Connection Strings for Configuration
print_info "Retrieving connection information..."
POSTGRES_FQDN=$(az postgres flexible-server show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_SERVER" \
    --query "fullyQualifiedDomainName" -o tsv)

APP_SERVICE_URL=$(az webapp show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE" \
    --query "defaultHostName" -o tsv)

# Step 17: Summary Output
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Completed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Resource Summary:${NC}"
echo ""
echo "App Service:"
echo "  Name:         $APP_SERVICE"
echo "  URL:          https://$APP_SERVICE_URL"
echo "  Plan:         $APP_SERVICE_PLAN ($TIER)"
echo ""
echo "PostgreSQL Database:"
echo "  Server:       $POSTGRES_SERVER"
echo "  FQDN:         $POSTGRES_FQDN"
echo "  Database:     $POSTGRES_DB"
echo "  Admin:        $POSTGRES_ADMIN"
echo "  Password:     ${POSTGRES_PASSWORD:0:10}... (stored in Key Vault)"
echo ""
echo "Key Vault:"
echo "  Name:         $KEY_VAULT"
echo "  Secrets:      5 (connection string, host, user, password, etc.)"
echo ""
echo "Monitoring:"
echo "  Application Insights: ${APP_SERVICE}-insights"
echo ""
echo -e "${YELLOW}IMPORTANT - NEXT STEPS:${NC}"
echo ""
echo "1. Update your application code:"
echo "   - Replace Cloudflare D1 adapter with PostgreSQL driver"
echo "   - Replace ChatGPT auth with Microsoft Entra ID"
echo "   - Update next.config.ts for Node.js runtime"
echo ""
echo "2. Deploy the application:"
echo "   - git remote add azure <deployment-url>"
echo "   - git push azure main"
echo ""
echo "3. Configure environment variables in App Service:"
echo "   - DATABASE_URL (already in Key Vault)"
echo "   - NODE_ENV=production"
echo "   - Other app-specific variables"
echo ""
echo "4. Migrate data:"
echo "   - Export from Cloudflare D1"
echo "   - Import to PostgreSQL"
echo "   - Validate record counts"
echo ""
echo "5. Configure Custom Domain (optional):"
echo "   - Add TLS binding"
echo "   - Configure DNS"
echo ""
echo -e "${YELLOW}Deployment URL (use for git push):${NC}"
APP_DEPLOYMENT_URL=$(az webapp deployment source config-local-git \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE" \
    --query "url" -o tsv)
echo "$APP_DEPLOYMENT_URL"
echo ""
echo -e "${YELLOW}Key Vault Access:${NC}"
echo "az keyvault secret list --vault-name $KEY_VAULT"
echo ""
echo -e "${YELLOW}Tail Application Logs:${NC}"
echo "az webapp log tail --name $APP_SERVICE --resource-group $RESOURCE_GROUP"
echo ""
echo -e "${YELLOW}Estimated Monthly Cost: \$145${NC}"
echo "  - App Service B2: \$85"
echo "  - PostgreSQL:     \$60"
echo ""
echo "Save this information for later reference!"
echo ""
