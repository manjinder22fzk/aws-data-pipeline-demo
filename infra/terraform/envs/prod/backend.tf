terraform {
  backend "s3" {
    bucket         = "money96-data-pipeline-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "money96-data-pipeline-tf-locks"
    encrypt        = true
  }
}