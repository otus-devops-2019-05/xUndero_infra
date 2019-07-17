variable zone {
  description = "Zone"
  default     = "europe-west1-d"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable private_key_path {
  description = "Path to the private key used for connect"
}

variable count {
  default = 1
}

variable db_internal_ip {}
