locals {
  reviewers_enabled = length(var.reviewer_user_ids) > 0 || length(var.reviewer_team_ids) > 0
  action_secrets    = { for secret in var.action_secrets : secret.secret_name => secret }
  action_variables  = { for variable in var.action_variables : variable.variable_name => variable }
}

resource "github_repository_environment" "this" {
  repository  = var.repository
  environment = var.environment
  wait_timer  = var.wait_timer

  dynamic "reviewers" {
    for_each = local.reviewers_enabled ? [1] : []
    content {
      users = var.reviewer_user_ids
      teams = var.reviewer_team_ids
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = var.deployment_branch_policy == null ? [] : [var.deployment_branch_policy]
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }
}

resource "github_actions_environment_secret" "this" {
  for_each = local.action_secrets

  repository  = var.repository
  environment = var.environment
  secret_name = each.value.secret_name

  plaintext_value = each.value.plaintext_value
  encrypted_value = each.value.encrypted_value
}

resource "github_actions_environment_variable" "this" {
  for_each = local.action_variables

  repository    = var.repository
  environment   = var.environment
  variable_name = each.value.variable_name
  value         = each.value.value
}
