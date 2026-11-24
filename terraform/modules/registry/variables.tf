variable "name" {
  description = "Short name for the local registry; k3d prefixes it with 'k3d-'."
  type        = string
  default     = "homelab-registry"
}

variable "host_port" {
  description = "Host port the registry is published on."
  type        = number
  default     = 5000
}
