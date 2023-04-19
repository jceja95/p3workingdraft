resource "aws_security_group" "bboys-elb-sg" {
    vpc_id = aws_vpc.bboys-vpc.id
    description = "security group for elb"
   
     tags = {
        Name = "${var.default_tags.env}-ELB-SG"
     }
     depends_on = [
       aws_vpc.bboys-vpc,
       aws_subnet.private,
       aws_subnet.public

     ]
}

resource "aws_security_group_rule" "elb-sg-ingress-443-from-internet" {
    description = "ingress on 443 from internet"
    type = "ingress"
    security_group_id = aws_security_group.bboys-elb-sg.id
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elb-sg-egress-80-to-ec2" {
  description = "80 outbound from elb to ec2"
  type = "egress"
  security_group_id = aws_security_group.bboys-elb-sg.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = aws_security_group.bboys-ec2-sg.id
}

resource "aws_security_group_rule" "elb-sg-egress-443-to-ec2" {
  description = "443 outbound from elb to ec2"
  type = "egress"
  security_group_id = aws_security_group.bboys-elb-sg.id
  from_port = 443
  to_port = 443
  protocol = "tcp"
  source_security_group_id = aws_security_group.bboys-ec2-sg.id
}