provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "ap-northeast-1"
  endpoints {
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  s3_use_path_style           = true
}
