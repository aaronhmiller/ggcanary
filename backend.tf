terraform {
  backend "s3" {
    profile        = "ux-validation" # Use same value as in tfvars
    region         = "us-west-2" # Use same value as in tfvars
    bucket         = "ggcanary-765182454900-bucket" # Use same value as in tfvars
    key            = "terraform.tfstate"
    dynamodb_table = "ggcanary-state-lock"
  }
}
