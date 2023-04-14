resource "aws_s3_bucket" "bboys-jd-test" {
    bucket = "bboys-jd-test"

    tags = {
        Name = "${var.default_tags.env}-S3"
    }
}

resource "aws_s3_bucket_policy" "jd-s3-bucket-policy" {
    bucket = aws_s3_bucket.bboys-jd-test.id
    policy = <<EOF
    {
        
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Public View",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::782863115905:role/jd-iam-terraform-role"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::bboys-jd-test/*"
        }
    ]
    }
    EOF
depends_on = [
  aws_iam_role_policy.jd-s3
]
}



resource "aws_s3_object" "s3-objects" {
   for_each = fileset("./s3-files/", "**")
    bucket = aws_s3_bucket.bboys-jd-test.id
    key = each.value
    source = "./s3-files/${each.value}"
    depends_on = [
      aws_s3_bucket_policy.jd-s3-bucket-policy
    ]
}

resource "aws_s3_bucket_public_access_block" "example" {
    bucket = aws_s3_bucket.bboys-jd-test.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
        
}

resource "aws_kms_key" "bboys-s3-key" {
  description = "key for bboys s3 sse"
  deletion_window_in_days = 30
  enable_key_rotation = true
 
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bboys-s3-sse-config" {
  bucket = aws_s3_bucket.bboys-jd-test.id
  rule  {
    apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.bboys-s3-key.arn
        sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "s3-bucket-logging" {
    bucket = aws_s3_bucket.bboys-jd-test.id
    target_bucket = aws_s3_bucket.bboys-jd-test.id
    target_prefix = "log/"
}