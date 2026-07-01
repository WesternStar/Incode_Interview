output "address" {
  description = "RDS host (no port)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.this.username
}

output "password" {
  description = "Master password"
  value       = random_password.master.result
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID attached to the database"
  value       = aws_security_group.this.id
}

output "arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}
