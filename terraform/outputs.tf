output "cluster_name" {
  description = "The k3d cluster name."
  value       = module.cluster.cluster_name
}

output "kubeconfig_context" {
  description = "The kubectl context name that reaches this cluster."
  value       = module.cluster.kubeconfig_context
}

output "network_name" {
  description = "The Docker network the cluster joins."
  value       = module.network.name
}

output "registry_host" {
  description = "Host endpoint for pushing images to the local registry."
  value       = module.registry.host
}
