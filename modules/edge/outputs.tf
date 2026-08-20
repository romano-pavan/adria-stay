output "cdn_domain_name" {
  value       = aws_cloudfront_distribution.assets.domain_name
  description = "cloudfront domain name"

}

output "assets_bucket_name" {
  value       = aws_s3_bucket.assets.id
  description = "S3 bucket name"
}