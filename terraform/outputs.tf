output "cluster_name" {
  description = "The k3d cluster name."
  value       = module.cluster.cluster_name
}

output "kubeconfig_context" {
  description = "The kubectl context name that reaches this cluster."
  value       = module.cluster.kubeconfig_context
}
