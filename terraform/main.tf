terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Multipass provider for local VMs
terraform {
  required_providers {
    multipass = {
      source = "larstobi/multipass"
      version = "~> 1.4.2"
    }
  }
}

resource "multipass_instance" "k8s_master" {
  name   = "k8s-master"
  cpus   = var.master_cpus
  memory = var.master_memory
  disk   = var.disk_size
  image  = var.ubuntu_image
}

resource "multipass_instance" "k8s_workers" {
  count  = var.worker_count
  name   = "k8s-worker${count.index + 1}"
  cpus   = var.worker_cpus
  memory = var.worker_memory
  disk   = var.disk_size
  image  = var.ubuntu_image
}
