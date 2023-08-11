#!/bin/bash
set -e

# Example variables required for this script
KUBERNETES_VERSION=1.25
PREFIX=ld-play-us
CLUSTER_NAME=aks-$PREFIX
RESOURCE_GROUP=$PREFIX-aks-rg
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION=WestUS
DNS_APP_NAME="$PREFIX-dns-app"
IP="$(curl -s https://api.ipify.org)"
KEY_VAULT_NAME=kv-$PREFIX

# Create Resource Group were AKS resources will reside
az group create -l $LOCATION -n $RESOURCE_GROUP

# Create Key Vault for AKS and App Registration secrets
key_vault_exists=$([[ $(az keyvault show -n $KEY_VAULT_NAME -g $RESOURCE_GROUP --query name -o tsv) == $KEY_VAULT_NAME ]] && echo "true" || echo "false")
key_vault_deleted=$(az keyvault list-deleted --query "[?name == \`$KEY_VAULT_NAME\`].name" -o tsv) || echo ""

# Check if key vault exists, if not check if purged, else create key vault
if [ $key_vault_exists == "false" ]; then
    if [ $key_vault_deleted == $KEY_VAULT_NAME ]; then
        echo "Key vault delete, recovering"
        az keyvault recover --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION 
    else
        echo "Key vault does not exist, creating"
        # Create a key vault with a network acl rule
        az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --network-acls-ips $IP
    fi
else
    echo "Key vault already exists"
fi


# create_app_registration () {
    # key_vault_name=$1
    # app_registration_name=$2
    # built_in_role=$3
    key_vault_name=$KEY_VAULT_NAME
    app_registration_name=$DNS_APP_NAME
    built_in_role="DNS Zone Contributor"

    echo "Creating app registration: $app_registration_name"
    existing_app=($(az ad app list --display-name $app_registration_name --query "[[0].appId,[0].objectId]" -o tsv | tr ' ' "\n"))
    existing_app_id="${existing_app[0]}"
    if [[ -z $existing_app_id  || $existing_app_id = "None" ]]; then
        app=($(az ad app create --display-name $app_registration_name --query "[appId,objectId]" -o tsv | tr ' ' "\n"))
        echo "${app}"
        app_id="${app[0]}"
        echo "App created with id: $app_id"
        password=$(openssl rand -base64 32)
        az ad app credential reset --id $app_id --credential-description "secret" --years 1 > /dev/null
        echo "Saving secret to key vault"
        az keyvault secret set --vault-name $key_vault_name --name "$app_registration_name-secret" --value $password
    else 
        echo "App registration already exists"
    fi

    echo "Creating service principal"
    sp_app_id=$([[ existing_app_id == "" ]] && echo $app_id || echo $existing_app_id)
    sp_object_id=$(az ad sp list --display-name $app_registration_name --query "[0].objectId" -o tsv)
    if [ $sp_object_id == "" ]; then
        az ad sp create --id $sp_app_id
    else echo "Service principal already exists"
    fi

    echo "Assigning built-in role: $built_in_role"
    az role assignment create --assignee-object-id $sp_object_id --role "$built_in_role" --scope /subscriptions/$SUBSCRIPTION_ID
# }

# Create required app registrations
# create_app_registration $KEY_VAULT_NAME $DNS_APP_NAME "DNS Zone Contributor"

# check if cluster exists and deploy if not
CLUSTER=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME > /dev/null) || echo ""
if [ -z $CLUSTER ]; then
    az aks create -g $RESOURCE_GROUP \
      -n $CLUSTER_NAME \
      --node-count 3 \
      --enable-addons monitoring \
      --enable-managed-identity \
      --kubernetes-version "$KUBERNETES_VERSION.11" \
      --load-balancer-managed-outbound-ip-count 2 \
      --node-vm-size "Standard_DS3_v2" \
      --generate-ssh-keys
else
    echo "Cluster already exists"
fi

# Get credentials for your new AKS cluster & login (interactive)
az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing
kubectl get nodes