resource "aws_launch_template" "bboys-ec2-launch-template" {
    name = "bboys-ec2-launch-template"
    image_id = "ami-0fa1de1d60de6a97e"
    instance_type = "t3.micro"
    key_name = "Jason_D"
      metadata_options {
      http_endpoint = "enabled"
    }
    instance_market_options {
    market_type = "spot"    
    }
    network_interfaces {
      security_groups = [aws_security_group.bboys-ec2-sg.id]

    }
    iam_instance_profile {
      name = aws_iam_instance_profile.launch-template-role.name
    } 
    user_data = filebase64("user-data.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.default_tags.env}-ASG-EC2"
    }
  }
    
    depends_on = [
      aws_security_group.bboys-ec2-sg,
      aws_iam_role.bboys-iam-terraform-role,
      aws_s3_object.s3-objects
    ]
}