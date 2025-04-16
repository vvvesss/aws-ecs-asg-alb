variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
}