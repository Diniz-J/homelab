output "name" {
  description = "The Docker network name created or reused by this module."
  value       = null_resource.network.triggers.name
}
