output "ecr_repository_url" {
  description = "URL del repositorio ECR para las imágenes de la aplicación"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "Certificado CA del cluster EKS (base64)"
  value       = module.eks.cluster_ca_certificate
}

