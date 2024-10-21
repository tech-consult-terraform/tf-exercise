# providers.tf


provider "aws" {
  profile = "default"
  region  = var.region
}
