terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
          }
    }
}

provider "aws" {
    region = "us-east-1"  
}



resource "aws_vpc" "jd-vpc-test" {
    cidr_block = "10.1.0.0/24"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    tags = {
        name = "JD-VPC-test"
        Name = "JD-VPC-test"
    }
}

resource "aws_iam_instance_profile" "launch-template-role" {
  name = "jd-launch-template-role"
  role = aws_iam_role.jd-iam-terraform-role.id
}


resource "aws_subnet" "public" {
    count = 2
    vpc_id = aws_vpc.jd-vpc-test.id
    cidr_block = cidrsubnet(aws_vpc.jd-vpc-test.cidr_block, 2, count.index)
    availability_zone = data.aws_availability_zones.name.names[count.index]
    map_public_ip_on_launch = false
    enable_resource_name_dns_a_record_on_launch = true
    tags = {
        Name = "${var.default_tags.env}-public-${data.aws_availability_zones.name.names[count.index]}"
            }
    
}

resource "aws_subnet" "private" {
   count = length(aws_subnet.public)
   vpc_id = aws_vpc.jd-vpc-test.id
    cidr_block = cidrsubnet(aws_vpc.jd-vpc-test.cidr_block, 2, count.index + 2)
    availability_zone = aws_subnet.public[count.index].availability_zone
    map_public_ip_on_launch = false
    enable_resource_name_dns_a_record_on_launch = true
    tags = {
        Name = "${var.default_tags.env}-private-${data.aws_availability_zones.name.names[count.index]}"
            }
            depends_on = [
              aws_subnet.public
            ]
}

resource "aws_internet_gateway" "jd-igw" {
    vpc_id = aws_vpc.jd-vpc-test.id
    tags = {
        Name = "${var.default_tags.env}-IGW"
    }
}

resource "aws_default_route_table" "jd-rt-main" {
    default_route_table_id = aws_vpc.jd-vpc-test.default_route_table_id
      route {
        cidr_block =  "0.0.0.0/0"
        gateway_id = aws_internet_gateway.jd-igw.id
    }
    tags = {
      "Name" = "${var.default_tags.env}-RT"
    }
    depends_on = [
      aws_subnet.private,
      aws_subnet.public    
    ]
}

resource "aws_route_table" "jd-rt-private" {
    vpc_id = aws_vpc.jd-vpc-test.id
    tags = {
        Name = "${var.default_tags.env}-private-RT"
    }
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.jd-vpc-test.id
    service_name = "com.amazonaws.us-east-1.s3"
    vpc_endpoint_type = "Gateway"
    tags = {
        Name = "${var.default_tags.env}-S3-Endpoint"
    }

}

resource "aws_vpc_endpoint_policy" "s3-endpoint-policy" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com",
                    "apigateway.amazonaws.com",
                    "ec2.amazonaws.com"
                ],
                "AWS": "arn:aws:sts::782863115905:assumed-role/AWSReservedSSO_Student_eee820b53800ca7b/jason.m.doyle1@gmail.com"
            },
            "Action": "*"
        }
    ]
})
}
resource "aws_vpc_endpoint_route_table_association" "s3-endpoint-main-route-association" {
 route_table_id = aws_default_route_table.jd-rt-main.id
 vpc_endpoint_id = aws_vpc_endpoint.s3.id
 depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.jd-rt-main
 ]
}

resource "aws_vpc_endpoint_route_table_association" "s3-endpoint-private-route-association" {
    route_table_id = aws_route_table.jd-rt-private.id
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
     depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.jd-rt-main
 ]
}



resource "aws_route_table_association" "public-subnet-route-table-associaiton" {
    count = length(aws_subnet.public)
    route_table_id = aws_default_route_table.jd-rt-main.id
    subnet_id = aws_subnet.public[count.index].id
     depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.jd-rt-main,
   aws_subnet.public
 ]
}


resource "aws_route_table_association" "private-subnet-route-table-association" {
    count = length(aws_subnet.private)
    route_table_id = aws_route_table.jd-rt-private.id
    subnet_id = aws_subnet.private[count.index].id 
     depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.jd-rt-main,
   aws_subnet.private
 ]
}


resource "aws_security_group" "jd-elb-sg" {
    vpc_id = aws_vpc.jd-vpc-test.id
    description = "security group for elb"
    ingress = [ {
      description = "allow all internet 443"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = true

     } ]
     tags = {
        Name = "${var.default_tags.env}-ELB-SG"
     }
     depends_on = [
       aws_vpc.jd-vpc-test,
       aws_subnet.private,
       aws_subnet.public

     ]
}


resource "aws_default_security_group" "default" {
    vpc_id = aws_vpc.jd-vpc-test.id
    ingress {
        description = "allow 80 from anywyere"
         from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = true
  }
  egress {
      description = "allow 443 outbound for s3"
         from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = []
      ipv6_cidr_blocks = []
      prefix_list_ids = [data.aws_prefix_list.s3.id]
      security_groups = []
      self = true
  }
  tags = {
    Name = "${var.default_tags.env}-Default-SG"
  }
    
}





resource "aws_security_group_rule" "main-sg-443-s3-egress" {
  security_group_id = aws_default_security_group.default.id
  description = "443 s3 outbound managed prefix"
  type = "egress"
  to_port = "443"
  from_port = "443"
  protocol = "tcp"
  prefix_list_ids = [data.aws_prefix_list.s3.id]

}

resource "aws_security_group" "jd-ec2-sg" {
    vpc_id = aws_vpc.jd-vpc-test.id
    description = "secrutiy group for ec2s in private subnet"
  ingress = [{
description = "allow all internet 80"
      description = "80 from elb"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = []
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = [aws_security_group.jd-elb-sg.id]
      self = true
  }]
  
  egress = [{
     description = "443 to s3"
     from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = []
      ipv6_cidr_blocks = []
      prefix_list_ids = [data.aws_prefix_list.s3.id]
      security_groups = []
      self = true
  }]
  tags = {
    Name = "${var.default_tags.env}-SG-EC2"
  }
}

resource "aws_security_group_rule" "ec2-80-main-ingress" {
    security_group_id = aws_security_group.jd-ec2-sg.id
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_default_security_group.default.id
}

resource "aws_security_group_rule" "ec2-443-alb-ingress" {
    description = "443 ingress for ec2 from alb"
    security_group_id = aws_security_group.jd-ec2-sg.id
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id = aws_security_group.jd-elb-sg.id
}

resource "aws_security_group_rule" "ec2-443-main-ingress" {
    description = "443 from main sg to ec2"
    security_group_id = aws_security_group.jd-ec2-sg.id
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id = aws_default_security_group.default.id
}

resource "aws_security_group_rule" "ec2-80-main-egress" {
  description = "inbound from default SG to ec2 port 80"
   security_group_id = aws_default_security_group.default.id
    type = "egress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_security_group.jd-ec2-sg.id    
}


resource "aws_security_group_rule" "elb-sg-to-ec2-rule" {
    type = "egress"
    description = "outbound port 80 from alb to EC2"
    security_group_id = aws_security_group.jd-elb-sg.id
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_security_group.jd-ec2-sg.id
}

resource "aws_security_group_rule" "elb-sg-to-ec2-443-rule" {
    type = "egress"
    description = "outbound port 443 from alb to EC2"
    security_group_id = aws_security_group.jd-elb-sg.id
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id = aws_security_group.jd-ec2-sg.id
}





