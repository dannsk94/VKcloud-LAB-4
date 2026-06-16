variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "m05-demo"
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
  sensitive   = true
  default     = "0.0.0.0/0"
}

variable "web_count" {
  description = "Number of web servers"
  type        = number
  default     = 2
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "appuser"
}

variable "image_name" {
  description = "Packer image ID"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = ""  # пусто для GitHub
}
