variable "enable_dynamo_encryption" {
  description = "Sets whether or not to enable KMS encryption for DynamoDB"
  type        = bool
  default     = false
}

variable "enable_lambda_env_encryption" {
  description = "Sets whether or not to enable KMS encryption for Lambda ENV"
  type        = bool
  default     = false
}

variable "enable_lambda_code_signing" {
  description = "Sets whether or not to enable Lambda code signing with AWS Signing Profiles"
  type        = bool
  default     = false
}

variable "hosted_zone" {
  description = "The hosted zone to configure for dynamic DNS"
  type        = string
}

variable "dyndns_hostname" {
  description = "The hostname to configure for dynamic DNS records"
  type        = string
}

variable "dyndns_shared_secret" {
  sensitive   = true
  description = "Shared Secret value to authorized records"
  type        = string
}