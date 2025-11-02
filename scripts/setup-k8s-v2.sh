#!/bin/bash

set -e

echo "🚀 Setting up Kubernetes cluster (v2 - Fixed)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run commands on VM
run_on_vm() {
    local vm_name=$1
    local command=$2
    echo -e "${YELLOW}Running on $vm_name:${NC} $command"
    multipass exec $vm_name -- bash -c "$command"
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    echo -e "${YELLOW}Waiting for pods in namespace $namespace to be ready...${NC}"
    kubectl wait --for=condition=Ready pods --all -n $namespace --timeout=${timeout}s || true
}

# Step 1: Install Kubernetes on all VMs
echo -e "${GREEN}Step 1: Installing Kubernetes on all VMs...${NC}"

for vm in k8s-master k8s-worker1 k8s-worker2; do
    echo -e "${YELLOW}Setting up $vm...${NC}"
    
    # Update and install prerequisites
    run_on_vm $vm "sudo apt update -y"
    run_on_vm $vm "sudo apt install -y apt-transport-https ca-certificates curl gpg"
    
    # Enable IP forwarding and disable swap
    run_on_vm $vm "sudo sysctl -w net.ipv4.ip_forward=1"
    run_on_vm $vm "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf"
    run_on_vm $vm "sudo swapoff -a"
    run_on_vm $vm "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
    
    # Configure containerd
    run_on_vm $vm "sudo mkdir -p /etc/containerd"
    run_on_vm $vm "containerd config default | sudo tee /etc/containerd/config.toml"
    run_on_vm $vm "sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml"
    
    # Add Kubernetes repository
    run_on_vm $vm "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
    run_on_vm $vm "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
    
    # Install Kubernetes components
    run_on_vm $vm "sudo apt update -y"
    run_on_vm $vm "sudo apt install -y kubelet kubeadm kubectl containerd"
    run_on_vm $vm "sudo apt-mark hold kubelet kubeadm kubectl"
    
    # Start and enable services
    run_on_vm $vm "sudo systemctl daemon-reload"
    run_on_vm $vm "sudo systemctl enable containerd kubelet"
    run_on_vm $vm "sudo systemctl restart containerd"
    
    echo -e "${GREEN}✅ $vm setup complete${NC}"
done

# Step 2: Initialize master node
echo -e "${GREEN}Step 2: Initializing master node...${NC}"

# Reset any previous cluster state
run_on_vm k8s-master "sudo kubeadm reset -f" || true

# Initialize cluster with Calico-compatible CIDR
run_on_vm k8s-master "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=10.6.253.177"

# Configure kubectl on master
run_on_vm k8s-master "mkdir -p /home/ubuntu/.kube"
run_on_vm k8s-master "sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config"
run_on_vm k8s-master "sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config"

echo -e "${GREEN}✅ Master node initialized${NC}"

# Step 3: Install Calico network plugin
echo -e "${GREEN}Step 3: Installing Calico network plugin...${NC}"

run_on_vm k8s-master "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml"

# Wait for Calico to be ready
echo -e "${YELLOW}Waiting for Calico pods to be ready...${NC}"
sleep 30
run_on_vm k8s-master "kubectl wait --for=condition=Ready pods --all -n calico-system --timeout=300s" || true

echo -e "${GREEN}✅ Calico network plugin installed${NC}"

# Step 4: Get join command and join workers
echo -e "${GREEN}Step 4: Joining worker nodes...${NC}"

# Reset workers first
for worker in k8s-worker1 k8s-worker2; do
    run_on_vm $worker "sudo kubeadm reset -f" || true
done

# Get fresh join command
JOIN_COMMAND=$(multipass exec k8s-master -- sudo kubeadm token create --print-join-command)

# Join workers to cluster
for worker in k8s-worker1 k8s-worker2; do
    echo -e "${YELLOW}Joining $worker to cluster...${NC}"
    run_on_vm $worker "sudo $JOIN_COMMAND"
    echo -e "${GREEN}✅ $worker joined cluster${NC}"
done

# Step 5: Install k9s and kubectl on host
echo -e "${GREEN}Step 5: Installing k9s and kubectl on host...${NC}"

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Copy kubeconfig from master
multipass exec k8s-master -- sudo cat /etc/kubernetes/admin.conf > ~/.kube/config

# Install k9s
if ! command -v k9s &> /dev/null; then
    echo "Installing k9s..."
    curl -sS https://webinstall.dev/k9s | bash
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "k9s already installed"
fi

echo -e "${GREEN}✅ k9s and kubectl installed${NC}"

# Step 6: Verify cluster
echo -e "${GREEN}Step 6: Verifying cluster...${NC}"

echo "Waiting for all nodes to be ready..."
sleep 60

echo "Cluster nodes:"
kubectl get nodes -o wide

echo -e "\nCluster pods:"
kubectl get pods --all-namespaces

echo -e "\n${GREEN}🎉 Kubernetes cluster setup complete!${NC}"
echo -e "${YELLOW}Cluster Information:${NC}"
echo "  Master: k8s-master (10.6.253.177)"
echo "  Worker1: k8s-worker1 (10.6.253.233)"
echo "  Worker2: k8s-worker2 (10.6.253.236)"
echo ""
echo -e "${YELLOW}To manage your cluster:${NC}"
echo "  k9s"
echo ""
echo -e "${YELLOW}To check cluster status:${NC}"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo ""
echo -e "${YELLOW}To deploy a test application:${NC}"
echo "  kubectl create deployment nginx --image=nginx"
echo "  kubectl expose deployment nginx --port=80 --type=NodePort"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  kubectl describe nodes"
echo "  kubectl logs -n calico-system -l k8s-app=calico-node"