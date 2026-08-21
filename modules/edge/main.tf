resource "aws_s3_bucket" "assets" {
  bucket        = "${var.name_prefix}-assets-${var.bucket_suffix}"
  force_destroy = true
  tags = {
    Name = "${var.name_prefix}-assets"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "test_image" {
  bucket       = aws_s3_bucket.assets.id
  key          = "index.html"
  content      = <<-EOT
  <div style="font-family: Arial, sans-serif; border: 1px solid #ccc; border-radius: 8px; padding: 16px; max-width: 300px; box-shadow: 2px 2px 10px rgba(0,0,0,0.1);">
  <h2 style="color: #2c3e50; margin-top: 0;">Pozdrav! 👋</h2>
  <p style="color: #555; line-height: 1.5;">Ovo je kratki HTML string s ugrađenim CSS stilom.</p>
  <button style="background-color: #3498db; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">Klikni me</button>
</div>
EOT
  content_type = "text/html; charset=utf-8"
}


resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.name_prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}


resource "aws_cloudfront_distribution" "assets" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  comment             = "${var.name_prefix}-cdn-assets"
  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "s3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }
  default_cache_behavior {
    target_origin_id           = "s3-assets"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = {
    Name = "${var.name_prefix}-cloudfront"
  }
}

data "aws_iam_policy_document" "assets" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.assets.arn]
    }
  }

}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"

}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets.json

}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }

}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    id = "expire-noncurrent"
    filter {}
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 30

    }


  }
}