#!/bin/bash

# Overwrite these required variables
LOCATION=WestUS
RESOURCE_GROUP=aks-rg
CLUSTER_NAME=aks-cluster

# Create Resource Group
az group create -l $LOCATION -n $RESOURCE_GROUP

# Deploy template with in-line parameters
az deployment group create -g $RESOURCE_GROUP  --template-uri https://github.com/Azure/AKS-Construction/releases/download/0.10.0/main.json --parameters \
	resourceName=$CLUSTER_NAME \
	agentCount=1 \
	upgradeChannel=stable \
	JustUseSystemPool=true \
	agentCountMax=20 \
	osDiskType=Managed \
	osDiskSizeGB=32 \
	custom_vnet=true \
	enable_aad=true \
	AksDisableLocalAccounts=true \
	enableAzureRBAC=true \
	adminPrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	registries_sku=Premium \
	acrPushRolePrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	omsagent=true \
	retentionInDays=30 \
	networkPolicy=azure \
	azurepolicy=audit \
	authorizedIPRanges="[\"109.36.131.187/32\"]" \
	ingressApplicationGateway=true \
	appGWcount=0 \
	appGWsku=WAF_v2 \
	appGWmaxCount=10 \
	appgwKVIntegration=true \
	keyVaultAksCSI=true \
	keyVaultCreate=true \
	keyVaultOfficerRolePrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	automationAccountScheduledStartStop=Weekday

