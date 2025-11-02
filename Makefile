.PHONY: help create-vms setup-k8s deploy clean destroy status install-tools k9s

# Default target
help:
	@echo "Kubernetes Infrastructure as Code"
	@echo ""
	@echo "Available targets:"
	@echo "  create-vms    - Create Multipass VMs"
	@echo "  setup-k8s     - Setup Kubernetes cluster"
	@echo "  deploy        - Full deployment (VMs + K8s + Apps)"
	@echo "  install-tools - Install kubectl and k9s on host"
	@echo "  k9s           - Launch k9s cluster manager"
	@echo "  status        - Show cluster status"
	@echo "  clean         - Clean up applications"
	@echo "  destroy       - Destroy entire infrastructure"
	@echo ""
	@echo "Terraform targets:"
	@echo "  tf-init       - Initialize Terraform"
	@echo "  tf-plan       - Plan Terraform changes"
	@echo "  tf-apply      - Apply Terraform changes"
	@echo "  tf-destroy    - Destroy Terraform resources"

# VM Management
create-vms:
	@echo "Creating VMs..."
	./scripts/create-vms.sh

# Kubernetes Setup
setup-k8s:
	@echo "Setting up Kubernetes..."
	./scripts/setup-k8s-v2.sh

# Full Deployment
deploy:
	@echo "Starting full deployment..."
	./scripts/deploy.sh

# Status Check
status:
	@echo "Cluster Status:"
	@multipass list
	@echo ""
	@kubectl get nodes -o wide 2>/dev/null || echo "Kubernetes not ready"
	@echo ""
	@kubectl get pods --all-namespaces 2>/dev/null || echo "No pods found"

# Cleanup
clean:
	@echo "Cleaning up applications..."
	kubectl delete -f k8s/ --ignore-not-found=true

# Destroy Infrastructure
destroy:
	@echo "Destroying infrastructure..."
	@kubectl delete -f k8s/ --ignore-not-found=true || true
	@multipass delete --all --purge || true
	@echo "Infrastructure destroyed"

# Tools Installation
install-tools:
	@echo "Installing kubectl and k9s..."
	@# Install kubectl if not present
	@if ! command -v kubectl >/dev/null 2>&1; then \
		echo "Installing kubectl..."; \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; \
		rm kubectl; \
	else \
		echo "kubectl already installed"; \
	fi
	@# Install k9s if not present
	@if ! command -v k9s >/dev/null 2>&1; then \
		echo "Installing k9s..."; \
		curl -sS https://webinstall.dev/k9s | bash; \
		export PATH="$$HOME/.local/bin:$$PATH"; \
	else \
		echo "k9s already installed"; \
	fi
	@echo "✅ Tools installation complete"

# Launch k9s
k9s:
	@if command -v k9s >/dev/null 2>&1; then \
		k9s; \
	else \
		echo "k9s not installed. Run 'make install-tools' first"; \
	fi

# Terraform targets
tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply

tf-destroy:
	cd terraform && terraform destroy