include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "providers" {
  path = find_in_parent_folders("providers/github.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/modules/github_repo_environment"
}

locals {
  tg_token_path = "${get_repo_root()}/vaults/tg/token.txt"
  tg_id_path    = "${get_repo_root()}/vaults/tg/id.txt"

  gh_repository_name = "workman-tw.github.io"
  environment        = "prod"
}

inputs = {
  repository  = local.gh_repository_name
  environment = local.environment
  deployment_branch_policy = {
    protected_branches     = true
    custom_branch_policies = false
  }
  action_secrets = [
    {
      secret_name     = "TG_BOT_TOKEN"
      plaintext_value = file(local.tg_token_path)
    }
  ]
  action_variables = [
    {
      variable_name     = "TG_ID"
      value             = file(local.tg_id_path)
    },
  ]
}
