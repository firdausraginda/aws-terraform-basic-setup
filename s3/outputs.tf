output "bucket_name" {
  value = aws_s3_bucket.etl.id
}

output "bucket_arn" {
  value = aws_s3_bucket.etl.arn
}
