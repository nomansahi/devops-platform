variable "app_image" {
  description = "Container image deployed for the practice application"
  type        = string
  default     = "practice-app:v1"
}

variable "replicas" {
  description = "Number of application pods"
  type        = number
  default     = 1

  validation {
    condition     = var.replicas >= 1 && var.replicas <= 3 && floor(var.replicas) == var.replicas
    error_message = "Replicas must be a whole number between 1 and 3 for this local lab."
  }
}