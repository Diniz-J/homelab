module "network" {
  source = "./modules/network"

  name = var.network_name
}

module "registry" {
  source = "./modules/registry"

  name      = var.registry_name
  host_port = var.registry_host_port
}

module "cluster" {
  source = "./modules/cluster"

  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  http_port    = var.http_port
  https_port   = var.https_port
  network      = module.network.name
  registry     = module.registry.name
}
