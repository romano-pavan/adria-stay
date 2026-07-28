resource "aws_s3_bucket" "adria-stay" {
  bucket        = "adria-stay-tfstate-rp"
  force_destroy = false

}

resource "aws_s3_bucket_public_access_block" "adria-stay" {
  bucket = aws_s3_bucket.adria-stay.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_server_side_encryption_configuration" "enkripcija" {
  bucket = aws_s3_bucket.adria-stay.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_versioning" "adria-stay" {
  bucket = aws_s3_bucket.adria-stay.id
  versioning_configuration {
    status = "Enabled"
  }
}