variable "cluster_name" {
  description = "Name used for the k3d cluster and the kubeconfig context (k3d-<name>)."
  type        = string
  default     = "homelab"
}

variable "k3s_version" {
  description = "k3s image tag used by k3d (rancher/k3s:<tag>)."
  type        = string
  default     = "v1.31.3-k3s1"
}

variable "http_port" {
  description = "Host port mapped to the cluster loadbalancer port 80."
  type        = number
  default     = 8080
}

variable "https_port" {
  description = "Host port mapped to the cluster loadbalancer port 443."
  type        = number
  default     = 8443
}
