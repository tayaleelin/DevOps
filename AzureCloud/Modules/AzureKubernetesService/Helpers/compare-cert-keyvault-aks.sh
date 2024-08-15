#!/bin/bash

# Variables (Replace with your values)
KEY_VAULT_NAME="<your-key-vault-name>"
CERT_NAME="<your-certificate-name>"
POD_NAMESPACE="<your-pod-namespace>"
POD_NAME="<your-pod-name>"
MOUNTED_CERT_PATH="/path/to/mounted/certificate.crt"

# Step 1: Retrieve the certificate from Azure Key Vault
echo "Retrieving certificate from Azure Key Vault..."
az keyvault certificate download --vault-name $KEY_VAULT_NAME --name $CERT_NAME --file kv_cert.pem

# Step 2: Extract the thumbprint of the Key Vault certificate
echo "Extracting thumbprint from the Key Vault certificate..."
KV_CERT_THUMBPRINT=$(openssl x509 -in kv_cert.pem -noout -fingerprint | sed 's/://g' | sed 's/SHA1 Fingerprint=//g')

# Step 3: Retrieve the mounted certificate from the Kubernetes pod
echo "Copying mounted certificate from Kubernetes pod..."
kubectl cp $POD_NAMESPACE/$POD_NAME:$MOUNTED_CERT_PATH ./mounted_cert.crt

# Step 4: Extract the thumbprint of the mounted certificate
echo "Extracting thumbprint from the mounted certificate..."
MOUNTED_CERT_THUMBPRINT=$(openssl x509 -in mounted_cert.crt -noout -fingerprint | sed 's/://g' | sed 's/SHA1 Fingerprint=//g')

# Step 5: Compare the thumbprints
echo "Comparing thumbprints..."
if [ "$KV_CERT_THUMBPRINT" == "$MOUNTED_CERT_THUMBPRINT" ]; then
    echo "Thumbprints match! Validation successful."
    exit 0
else
    echo "Thumbprints do not match! Validation failed."
    exit 1
fi