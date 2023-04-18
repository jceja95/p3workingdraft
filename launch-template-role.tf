resource "aws_iam_role" "bboys-iam-terraform-role" {
  name = "bboys-iam-terraform-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:sts::782863115905:assumed-role/AWSReservedSSO_Student_eee820b53800ca7b/jason.m.doyle1@gmail.com",
                "Service": [
                    "apigateway.amazonaws.com",
                    "lambda.amazonaws.com",
                    "ec2.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
}

resource "aws_iam_role_policy" "bboys-ec2"{
  name = "bboys-iam-policy-ec2"
  role = aws_iam_role.bboys-iam-terraform-role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ec2scheduled.amazonaws.com",
                        "elasticloadbalancing.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "transitgateway.amazonaws.com"
                    ]
                }
            }
        }
    ]
})
depends_on = [
  aws_iam_role.bboys-iam-terraform-role
]
}

resource "aws_iam_role_policy" "bboys-s3" {
  name = "bboys-iam-s3-permissions"
  role = aws_iam_role.bboys-iam-terraform-role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": "*"
        }
    ]
})
depends_on = [
  aws_iam_role.bboys-iam-terraform-role
]
}
