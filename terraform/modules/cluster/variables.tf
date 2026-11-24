variable "cluster_name" {
  description = "Name of the k3d cluster."
  type        = string
}

variable "k3s_version" {
  description = "k3s image tag (rancher/k3s:<tag>)."
  type        = string
}

variable "http_port" {
  description = "Host port mapped to loadbalancer port 80."
  type        = number
}

variable "https_port" {
  description = "Host port mapped to loadbalancer port 443."
  type        = number
}

variable "network" {
  description = "Docker network the cluster joins; empty for k3d's default."
  type        = string
  default     = ""
}

variable "registry" {
  description = "Local k3d registry name (k3d- prefix included) passed via --registry-use; empty for none."
  type        = string
  default     = ""
}
