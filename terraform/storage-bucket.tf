/*terraform {
  required_version = ">= 0.11.7"
}*/

provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["mynew-storage-bucket", "storage-bucket-terra"]
}
