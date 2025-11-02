# Kubernetes Infrastructure as Code

This project provides Infrastructure as Code (IaC) for setting up a local Kubernetes cluster using Multipass VMs.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Host Ubuntu (16GB RAM)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ k8s-master  │  │ k8s-worker1 │  │ k8s-worker2 │        │
│  │ 4GB/2CPU    │  │ 2GB/2CPU    │  │ 2GB/2CPU    │        │
│  │ Control     │  │ Worker      │  │ Worker      │        │
│  │ Plane       │  │ Node        │  │ Node        │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Ubuntu host with 16GB+ RAM
- Multipass installed
- Terraform installed (optional)
- Ansible installed (optional)
- kubectl installed

## Quick Start

### Option 1: Manual Script (Fastest)
```bash
# Create VMs and setup Kubernetes
./scripts/create-vms.sh
./scripts/setup-k8s-v2.sh
```

### Option 2: Terraform + Ansible (IaC)
```bash
# Create VMs with Terraform
cd terraform/
terraform init
terraform plan
terraform apply

# Setup Kubernetes with Ansible
cd ../ansible/
ansible-playbook -i inventory.ini playbook.yml

# Deploy applications
cd ../k8s/
kubectl apply -f nginx.yaml
```

### Option 3: Azure DevOps Pipeline
1. Push code to Azure DevOps repository
2. Pipeline will automatically:
   - Create VMs
   - Setup Kubernetes
   - Deploy applications

## Project Structure

```
k8s-infrastructure/
├── terraform/          # VM provisioning
│   ├── main.tf         # Multipass resources
│   ├── variables.tf    # Configuration variables
│   └── outputs.tf      # VM information
├── ansible/            # Kubernetes setup
│   ├── playbook.yml    # K8s installation
│   └── inventory.ini   # VM inventory
├── k8s/               # Application manifests
│   ├── nginx.yaml     # Test application
│   └── calico.yaml    # Network plugin
├── scripts/           # Automation scripts
│   ├── create-vms.sh  # VM creation
│   └── setup-k8s-v2.sh # K8s setup
└── azure-pipelines.yml # CI/CD pipeline
```

## Network Architecture

### Three Network Layers:
1. **Host Network (10.6.253.x)** - VM-to-VM communication
2. **Pod Network (192.168.x.x)** - Pod-to-pod communication via Calico
3. **Service Network (10.96.x.x)** - Stable service IPs via kube-proxy

## Usage

### Access the cluster:
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Access nginx service
kubectl get svc nginx-service
# Visit http://<node-ip>:<nodeport>

# Use k9s for cluster management
k9s
```

### Manage VMs:
```bash
# List VMs
multipass list

# SSH into VMs
multipass shell k8s-master
multipass shell k8s-worker1

# Stop/Start VMs
multipass stop --all
multipass start --all
```

## Customization

Edit `terraform/variables.tf` to customize:
- VM resources (CPU, memory, disk)
- Number of worker nodes
- Ubuntu image version

## Troubleshooting

### Common Issues:
1. **VMs not starting**: Check available resources
2. **Network issues**: Verify Calico pods are running
3. **Join failures**: Check firewall and network connectivity

### Debug Commands:
```bash
# Check VM status
multipass list

# Check Kubernetes components
kubectl get pods -n kube-system

# Check logs
kubectl logs -n kube-system -l k8s-app=calico-node

# Check node status
kubectl describe nodes
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Destroy VMs
multipass delete --all --purge

# Or with Terraform
terraform destroy
```