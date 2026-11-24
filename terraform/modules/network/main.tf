resource "null_resource" "network" {
  triggers = {
    name = var.name
  }

  provisioner "local-exec" {
    command = "docker network inspect ${var.name} >/dev/null 2>&1 || docker network create ${var.name}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker network rm ${self.triggers.name} || true"
  }
}
