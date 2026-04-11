locals {
  gh_pat_path = "${get_repo_root()}/vaults/github/repo-class-pat.txt"
  gh_pat      = file(local.gh_pat_path)
  gh_org      = "workman-tw"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  contents  = <<EOF
provider "github" {
  owner = "${local.gh_org}"
  token = "${local.gh_pat}"
}
EOF
}
