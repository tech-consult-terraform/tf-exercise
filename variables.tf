# variables.tf

variable "region" {
  description = "Region for my manifest. The AMI is tied to this region"
  default     = "us-east-2"
}

variable "sku" {
  description = "Instance Type"
  default = "t4g.nano"
}