output "master_ip" {
  description = "IP address of the master node"
  value       = multipass_instance.k8s_master.ipv4
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value       = multipass_instance.k8s_workers[*].ipv4
}

output "all_nodes" {
  description = "All node information"
  value = {
    master = {
      name = multipass_instance.k8s_master.name
      ip   = multipass_instance.k8s_master.ipv4
    }
    workers = [
      for worker in multipass_instance.k8s_workers : {
        name = worker.name
        ip   = worker.ipv4
      }
    ]
  }
}