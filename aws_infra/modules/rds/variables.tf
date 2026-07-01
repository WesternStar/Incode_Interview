variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "engine" {
  description = "RDS database engine"
  type        = string
}

variable "engine_version" {
  description = "RDS database engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage, in GB"
  type        = number
}

variable "storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432
}

variable "vpc_id" {
  description = "VPC ID to deploy the database into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (should be private)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to reach the database on var.port"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key ARN used to encrypt database storage. If not set, storage is left unencrypted."
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Whether to deploy a standby replica in another AZ"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the database has a publicly resolvable DNS name"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the database and its supporting resources"
  type        = map(string)
  default     = {}
}
