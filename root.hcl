locals {
  tf_state_dir = "${get_repo_root()}/tfstate"
}

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${local.tf_state_dir}/${path_relative_to_include()}/terraform.tfstate"
  }
}
