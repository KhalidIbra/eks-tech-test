resource "aws_db_subnet_group" "main" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

#------------------ RDS Parameter Group ------------------#

resource "aws_db_parameter_group" "main" {
  name   = "${var.identifier}-pg"
  family = "mysql8.0"

  tags = var.tags
}

#--------------------- RDS Database -------------------#

resource "aws_db_instance" "mysql" {
  identifier     = var.identifier
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = 3306

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.allowed_security_group_ids
  parameter_group_name   = aws_db_parameter_group.main.name
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot   = true

  
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  # Performance Insights is free for 7 days 
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  
  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,  
      password,
    ]                  
  }

  tags = merge(var.tags, {
    Name = var.identifier
  })
}

#------------------ AWS Secrets Manager Secret for DB Credentials ------------------#

resource "random_password" "master" {     # Generates a random password for the RDS master user
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.identifier}-db-credentials"
  description = "Master credentials for RDS instance ${var.identifier}"

  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = var.database_name
  })
}