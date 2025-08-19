#!/bin/bash

set -e

RESOURCE_GROUP="litmuschaos-demo-tfstate"
STORAGE_ACCOUNT="litmuschaosdemotfstate"
CONTAINER_NAME="tfstate"
LOCATION="westeurope"

echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating storage account..."
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

echo "Getting storage account key..."
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

echo "Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

echo "Backend storage setup complete!"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"