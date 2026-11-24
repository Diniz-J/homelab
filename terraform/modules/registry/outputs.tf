output "name" {
  description = "Full registry name (k3d- prefix included) the cluster passes to --registry-use."
  value       = "k3d-${null_resource.registry.triggers.name}"
}

output "host_port" {
  description = "Host port the registry publishes."
  value       = null_resource.registry.triggers.host_port
}

output "host" {
  description = "Host endpoint for pushing images from outside the cluster."
  value       = "localhost:${null_resource.registry.triggers.host_port}"
}
