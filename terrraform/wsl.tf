provider "local" {
}

resource "null_resource" "export_wsl" {
  provisioner "local-exec" {
    command = "wsl --export Ubuntu-24.04 E:\\WSL\\ubuntu-backup.tar"
  }
}

resource "null_resource" "import_wsl_1" {
  depends_on = [null_resource.export_wsl]

  provisioner "local-exec" {
    command = "wsl --import U1 E:\\WSL\\U1 E:\\WSL\\ubuntu-backup.tar"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "wsl --unregister U1"
  }
}

resource "null_resource" "import_wsl_2" {
  depends_on = [null_resource.export_wsl]

  provisioner "local-exec" {
    command = "wsl --import U2 E:\\WSL\\U2 E:\\WSL\\ubuntu-backup.tar"
  }


  provisioner "local-exec" {
    when    = destroy
    command = "wsl --unregister U2"
  }
}
