terraform {
  # Версия terraform
  required_version = ">= 0.11.7"
}

provider "google" {
  # Версия провайдера
  version = "2.0.0"

  # ID проекта
  project = "${var.project}"

  region = "${var.region}"
}

resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = "appuser1:${file(var.public_key_path)}appuser2:${file(var.public_key_path)}appuser3:${file(var.public_key_path)}"
  }
}

/*resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "appuser2"
  value = "${file(var.public_key_path)}"
  key   = "appuser3"
  value = "${file(var.public_key_path)}"
  key   = "appuser4"
  value = "${file(var.public_key_path)}"
}*/

resource "google_compute_instance" "app" {
  name         = "reddit-app"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]

  metadata {
    #путь до публичного ключа
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа из Интернет
    access_config {}
  }

  connection {
    type  = "ssh"
    user  = "appuser"
    agent = false

    #путь до ключа
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"

  #название сети, в которой действует правило
  network = "default"

  #какой доступ
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  #каким адресам
  source_ranges = ["0.0.0.0/0"]

  #тэг для применения
  target_tags = ["reddit-app"]
}
