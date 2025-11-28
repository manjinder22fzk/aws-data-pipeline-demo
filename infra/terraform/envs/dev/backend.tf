# terraform {
#   backend "s3" {
#     bucket         = "replace-with-your-tf-state-bucket-dev"
#     key            = "aws-data-pipeline-demo/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "replace-with-your-tf-lock-table-dev"
#     encrypt        = true
#   }
# }
