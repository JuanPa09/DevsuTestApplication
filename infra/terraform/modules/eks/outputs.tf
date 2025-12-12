output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificado CA del cluster EKS (base64)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}
