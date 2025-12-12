variable "name_prefix" {
  description = "Prefijo para nombres de recursos (project-env)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Número de Availability Zones a usar"
  type        = number
  default     = 2
}
