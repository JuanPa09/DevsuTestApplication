output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = [for s in aws_subnet.public : s.id]
}
