variable "repository" {
  description = "name of the GitHub repository."
  type        = string
}

variable "environment" {
  description = "name of the environment."
  type        = string
}

variable "wait_timer" {
  description = "number of minutes to wait before starting a deployment."
  type        = number
  default     = null
}

variable "reviewer_user_ids" {
  description = "GitHub user IDs that can approve deployments."
  type        = list(number)
  default     = []
}

variable "reviewer_team_ids" {
  description = "GitHub team IDs that can approve deployments."
  type        = list(number)
  default     = []
}

variable "deployment_branch_policy" {
  description = "branch policy settings for the environment."
  type = object({
    protected_branches     = bool
    custom_branch_policies = bool
  })
  default = null
}

variable "action_secrets" {
  description = "environment secrets for GitHub Actions."
  type = list(object({
    secret_name     = string
    plaintext_value = optional(string)
    encrypted_value = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for secret in var.action_secrets :
      (secret.plaintext_value != null) != (secret.encrypted_value != null)
    ])
    error_message = "Each action_secrets entry must set exactly one of plaintext_value or encrypted_value."
  }
}

variable "action_variables" {
  description = "environment variables for GitHub Actions."
  type = list(object({
    variable_name = string
    value         = string
  }))
  default = []
}
