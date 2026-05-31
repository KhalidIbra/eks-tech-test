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

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret that RDS manages with master credentials"
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

output "db_credentials_secret_id" {
  description = "Secret ID for use with aws secretsmanager get-secret-value"
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}