
resource "aws_default_security_group" "default" {
    vpc_id = aws_vpc.bboys-vpc.id
    
  
  tags = {
    Name = "${var.default_tags.env}-Default-SG"
  }
}  


resource "aws_security_group_rule" "default-sg-80-egress-to-ec2" {
  description = "80 outbound to ec2"
  type = "egress"
  security_group_id = aws_default_security_group.default.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = aws_security_group.bboys-ec2-sg.id
}

resource "aws_security_group_rule" "default-sg-443-egress-to-ec2" {
  description = "443 outbout to ec2"
  type = "egress"
  security_group_id = aws_default_security_group.default.id
  from_port = 443
  to_port = 443
  protocol = "tcp"
  source_security_group_id = aws_security_group.bboys-ec2-sg.id

}

resource "aws_security_group_rule" "default-sg-443-egress-to-s3" {
    description = "443 outbound to s3 managed prefix"
    type = "egress"
    security_group_id = aws_default_security_group.default.id
    from_port = 443
    to_port = 443
    protocol = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
}

resource "aws_security_group_rule" "default-sg-ssh-ingress-from-internet" {
  description = "ssh ingress from any"
  type = "ingress"
  security_group_id = aws_default_security_group.default.id
  from_port = 22
  to_port = 22
  cidr_blocks = ["0.0.0.0/0"]
  protocol = "tcp"
  }

 

