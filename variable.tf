variable "vpc_cidr" {
  description = "VPC CIDR Range Value"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "custome-vpc"
}