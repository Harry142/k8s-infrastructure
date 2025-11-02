variable "master_cpus" {
  description = "Number of CPUs for master node"
  type        = number
  default     = 2
}

variable "master_memory" {
  description = "Memory for master node"
  type        = string
  default     = "4G"
}

variable "worker_cpus" {
  description = "Number of CPUs for worker nodes"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "Memory for worker nodes"
  type        = string
  default     = "2G"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Disk size for all nodes"
  type        = string
  default     = "20G"
}

variable "ubuntu_image" {
  description = "Ubuntu image version"
  type        = string
  default     = "22.04"
}