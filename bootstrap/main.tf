resource "aws_s3_bucket" "adria-stay" {
  #checkov:skip=CKV_AWS_145:SSE-S3 is enabled, a customer managed KMS key adds cost and rotation work without changing the threat model here
  #checkov:skip=CKV_AWS_18:access logging needs a second bucket nobody reads
  #checkov:skip=CKV_AWS_144:cross-region replication costs money, the state can be rebuilt from the repository
  #checkov:skip=CKV2_AWS_62:event notifications have no consumer in this project
  #checkov:skip=CKV2_AWS_61:this bucket keeps state history on purpose, expiring old versions would delete the rollback path
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

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
   
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:romano-pavan/adria-stay:*"]
    }
  }
  
}

resource "aws_iam_role" "github_actions" {
  name = "adria-stay-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
  tags = {
    Name = "github-actions"
  }
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  
}

data "aws_iam_policy_document" "state_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.adria-stay.arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.adria-stay.arn]
  }
}



resource "aws_iam_role_policy" "state_access" {
  name = "state-access"
  role = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.state_access.json
}