#!/bin/bash

set -e

echo "🚀 Deploying Kubernetes Infrastructure..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists multipass; then
    echo -e "${RED}Error: multipass is not installed${NC}"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Step 1: Create VMs
echo -e "${GREEN}Step 1: Creating VMs with Multipass...${NC}"
./scripts/create-vms.sh

# Wait for VMs to be ready
echo -e "${YELLOW}Waiting for VMs to be ready...${NC}"
sleep 30

# Step 2: Setup Kubernetes
echo -e "${GREEN}Step 2: Setting up Kubernetes cluster...${NC}"
./scripts/setup-k8s-v2.sh

# Step 3: Deploy applications
echo -e "${GREEN}Step 3: Deploying applications...${NC}"

# Wait for cluster to be ready
echo -e "${YELLOW}Waiting for cluster to be ready...${NC}"
sleep 60

# Deploy nginx
kubectl apply -f k8s/nginx.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/nginx

echo -e "${GREEN}✅ Deployment complete!${NC}"

# Show cluster information
echo -e "\n${YELLOW}Cluster Information:${NC}"
kubectl get nodes -o wide
echo ""
kubectl get pods --all-namespaces
echo ""
kubectl get services

# Get nginx service info
NGINX_PORT=$(kubectl get svc nginx-service -o jsonpath='{.spec.ports[0].nodePort}')
MASTER_IP=$(multipass info k8s-master | grep IPv4 | awk '{print $2}')

echo -e "\n${GREEN}🎉 Kubernetes cluster is ready!${NC}"
echo -e "${YELLOW}Access nginx at: http://${MASTER_IP}:${NGINX_PORT}${NC}"
echo -e "${YELLOW}Use 'k9s' to manage your cluster${NC}"