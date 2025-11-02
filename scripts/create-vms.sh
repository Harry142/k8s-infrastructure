#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Creating Kubernetes VMs...${NC}"

# Function to create VM with error handling
create_vm() {
    local name=$1
    local cpus=$2
    local memory=$3
    local disk=$4
    
    echo -e "${YELLOW}Creating $name (CPUs: $cpus, Memory: $memory, Disk: $disk)...${NC}"
    
    if multipass launch --name $name --cpus $cpus --memory $memory --disk $disk 22.04; then
        echo -e "${GREEN}✅ $name created successfully${NC}"
        
        # Wait for VM to be ready and get IP
        echo -e "${YELLOW}Waiting for $name to get IP address...${NC}"
        local ip=""
        local attempts=0
        while [ -z "$ip" ] && [ $attempts -lt 30 ]; do
            sleep 2
            ip=$(multipass info $name | grep IPv4 | awk '{print $2}' || true)
            attempts=$((attempts + 1))
        done
        
        if [ -n "$ip" ]; then
            echo -e "${GREEN}$name IP: $ip${NC}"
        else
            echo -e "${YELLOW}Warning: Could not get IP for $name${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to create $name${NC}"
        echo -e "${YELLOW}Attempting to clean up and retry...${NC}"
        
        # Clean up failed VM
        multipass delete $name --purge 2>/dev/null || true
        
        # Retry once
        echo -e "${YELLOW}Retrying $name creation...${NC}"
        if multipass launch --name $name --cpus $cpus --memory $memory --disk $disk 22.04; then
            echo -e "${GREEN}✅ $name created successfully on retry${NC}"
        else
            echo -e "${RED}❌ Failed to create $name after retry${NC}"
            return 1
        fi
    fi
}

# Check if multipass is installed
if ! command -v multipass &> /dev/null; then
    echo -e "${RED}❌ Multipass is not installed${NC}"
    exit 1
fi

# Clean up any existing VMs with same names
echo -e "${YELLOW}Cleaning up existing VMs...${NC}"
for vm in k8s-master k8s-worker1 k8s-worker2; do
    if multipass info $vm &>/dev/null; then
        echo -e "${YELLOW}Deleting existing $vm...${NC}"
        multipass delete $vm --purge
    fi
done

# Create VMs
create_vm "k8s-master" 2 "4G" "20G"
create_vm "k8s-worker1" 2 "2G" "15G"
create_vm "k8s-worker2" 2 "2G" "15G"

echo -e "\n${GREEN}🎉 All VMs created successfully!${NC}"
echo -e "${YELLOW}VM Status:${NC}"
multipass list

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  make setup-k8s    # Setup Kubernetes cluster"
echo -e "  make deploy       # Full deployment"