locals {
  gcp_vars = read_terragrunt_config(find_in_parent_folders("gcp.hcl"))
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project     = local.gcp_vars.locals.project_id
    location    = local.gcp_vars.locals.location
    bucket      = "${local.gcp_vars.locals.bucket_name}-${local.env_vars.locals.name}"
    prefix      = "${path_relative_to_include()}/terraform.tfstate"
    credentials = local.gcp_vars.locals.credential_file_path
  }
}
