/*module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["terraform-2-mynew-storage-bucket"]
}*/

terraform {
  backend "gcs" {
    bucket = "storage-app"
    prefix = "prod"
  }
}
