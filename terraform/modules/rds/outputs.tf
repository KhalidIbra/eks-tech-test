output "db_instance_endpoint" {
  description = "Connection endpoint (host:port) for the database"
  value       = aws_db_instance.mysql.endpoint
}

output "db_instance_address" {
  description = "Hostname of the database (no port)"
  value       = aws_db_instance.mysql.address
}

output "db_instance_port" {
  description = "Database port"
  value       = aws_db_instance.mysql.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.mysql.db_name
}

output "db_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of the Secrets Manager secret (use this in External Secrets Operator)"
  value       = aws_secretsmanager_secret.db_credentials.name
}