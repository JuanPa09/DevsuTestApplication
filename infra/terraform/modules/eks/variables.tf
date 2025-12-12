variable "name_prefix" {
  description = "Prefijo para nombres del cluster EKS (project-env)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde vivirá el cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets donde se desplegarán el cluster y los nodos"
  type        = list(string)
}

variable "cluster_version" {
  description = "Versión de Kubernetes para el cluster EKS"
  type        = string
  default     = "1.30"
}

variable "desired_size" {
  description = "Número deseado de nodos en el node group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Número mínimo de nodos en el node group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Número máximo de nodos en el node group"
  type        = number
  default     = 3
}

variable "instance_types" {
  description = "Tipos de instancia para los nodos del cluster"
  type        = list(string)
  default     = ["t3.small"]
}

variable "disk_size" {
  description = "Tamaño del disco de los nodos en GB"
  type        = number
  default     = 20
}
