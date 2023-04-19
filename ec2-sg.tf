resource "aws_security_group" "bboys-ec2-sg" {
    vpc_id = aws_vpc.bboys-vpc.id
    description = "secrutiy group for ec2s in private subnet"
  
  tags = {
    Name = "${var.default_tags.env}-SG-EC2"
  }
}

resource "aws_security_group_rule" "ec2-sg-80-ingress-from-elb" {
    description = "80 ingress from elb to ec2"
    type = "ingress"
    security_group_id = aws_security_group.bboys-ec2-sg.id
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_security_group.bboys-elb-sg.id
}

resource "aws_security_group_rule" "ec2-sg-443-ingress-from-elb" {
    description = "443 ingress from elb to ec2"
    type = "ingress"
    security_group_id = aws_security_group.bboys-ec2-sg.id
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id = aws_security_group.bboys-elb-sg.id
}

resource "aws_security_group_rule" "ec2-sg-443-egress-to-s3" {
  type = "egress"
  description = "443 egress to s3 managed prefix"
  security_group_id = aws_security_group.bboys-ec2-sg.id
  from_port = 443
  to_port = 443
  protocol = "tcp"
  prefix_list_ids = [data.aws_prefix_list.s3.id]
  }