resource "null_resource" "registry" {
  triggers = {
    name      = var.name
    host_port = tostring(var.host_port)
  }

  provisioner "local-exec" {
    command = "k3d registry list k3d-${var.name} >/dev/null 2>&1 || k3d registry create ${var.name} --port 0.0.0.0:${var.host_port}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d registry delete k3d-${self.triggers.name} || true"
  }
}
