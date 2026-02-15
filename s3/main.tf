resource "aws_s3_bucket" "etl" {
  bucket        = "dummy-etl-pipeline-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

data "aws_caller_identity" "current" {}
