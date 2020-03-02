variable "vpc_id" {
  description = "The VPC id"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The private subnets to use"
}