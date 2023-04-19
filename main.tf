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



resource "aws_vpc" "bboys-vpc" {
    cidr_block = "10.1.0.0/24"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    tags = {
        name = "bboys-vpc"
        Name = "bboys-vpc"
    }
}

resource "aws_iam_instance_profile" "launch-template-role" {
  name = "bboys-launch-template-role"
  role = aws_iam_role.bboys-iam-terraform-role.id
}


resource "aws_subnet" "public" {
    count = 2
    vpc_id = aws_vpc.bboys-vpc.id
    cidr_block = cidrsubnet(aws_vpc.bboys-vpc.cidr_block, 2, count.index)
    availability_zone = data.aws_availability_zones.name.names[count.index]
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    tags = {
        Name = "${var.default_tags.env}-public-${data.aws_availability_zones.name.names[count.index]}"
            }
    
}

resource "aws_subnet" "private" {
   count = length(aws_subnet.public)
   vpc_id = aws_vpc.bboys-vpc.id
    cidr_block = cidrsubnet(aws_vpc.bboys-vpc.cidr_block, 2, count.index + 2)
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

resource "aws_internet_gateway" "bboys-igw" {
    vpc_id = aws_vpc.bboys-vpc.id
    tags = {
        Name = "${var.default_tags.env}-IGW"
    }
}

resource "aws_default_route_table" "bboys-rt-main" {
    default_route_table_id = aws_vpc.bboys-vpc.default_route_table_id
      route {
        cidr_block =  "0.0.0.0/0"
        gateway_id = aws_internet_gateway.bboys-igw.id
    }
    tags = {
      "Name" = "${var.default_tags.env}-RT"
    }
    depends_on = [
      aws_subnet.private,
      aws_subnet.public    
    ]
}

resource "aws_route_table" "bboys-rt-private" {
    vpc_id = aws_vpc.bboys-vpc.id
    tags = {
        Name = "${var.default_tags.env}-private-RT"
    }
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.bboys-vpc.id
    service_name = "com.amazonaws.us-east-1.s3"
    vpc_endpoint_type = "Gateway"
    tags = {
        Name = "${var.default_tags.env}-S3-Endpoint"
    }

}

resource "aws_vpc_endpoint_policy" "s3-endpoint-policy" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  policy = jsonencode({
	"Version": "2008-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": "*",
			"Action": "*",
			"Resource": "*"
		}
	]
})
}
resource "aws_vpc_endpoint_route_table_association" "s3-endpoint-main-route-association" {
 route_table_id = aws_default_route_table.bboys-rt-main.id
 vpc_endpoint_id = aws_vpc_endpoint.s3.id
 depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.bboys-rt-main
 ]
}

resource "aws_vpc_endpoint_route_table_association" "s3-endpoint-private-route-association" {
    route_table_id = aws_route_table.bboys-rt-private.id
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
     depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.bboys-rt-main
 ]
}



resource "aws_route_table_association" "public-subnet-route-table-associaiton" {
    count = length(aws_subnet.public)
    route_table_id = aws_default_route_table.bboys-rt-main.id
    subnet_id = aws_subnet.public[count.index].id
     depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.bboys-rt-main,
   aws_subnet.public
 ]
}


resource "aws_route_table_association" "private-subnet-route-table-association" {
    count = length(aws_subnet.private)
    route_table_id = aws_route_table.bboys-rt-private.id
    subnet_id = aws_subnet.private[count.index].id 
     depends_on = [
   aws_vpc_endpoint.s3,
   aws_default_route_table.bboys-rt-main,
   aws_subnet.private
 ]
}








