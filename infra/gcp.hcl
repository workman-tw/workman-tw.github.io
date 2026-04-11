locals {
  bucket_name          = "workman-tw-github-io"
  project_id           = "rex-lab-407322"
  location             = "asia-east1"
  credential_file_path = "${get_repo_root()}/vaults/gcp/gcp-sa.json"
}
