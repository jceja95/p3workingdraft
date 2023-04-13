resource "aws_s3_bucket" "bboys-jd-test" {
    bucket = "bboys-jd-test"

    tags = {
        Name = "${var.default_tags.env}-S3"
    }
}

data "aws_iam_policy_document" "jd-s3-iam-policy" {
    statement {
        actions = ["s3:*"]
        resources = [aws_s3_bucket.bboys-jd-test.id]
        principals {
          type = "AWS"
          identifiers = ["arn:aws:iam::782863115905:role/jd-iam-terraform-role"]

        }
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

resource "aws_s3_object" "index-file" {
    bucket = aws_s3_bucket.bboys-jd-test.id
    source = "index.html"
    key = "index.html"
    depends_on = [
      aws_s3_bucket_policy.jd-s3-bucket-policy
    ]
}
