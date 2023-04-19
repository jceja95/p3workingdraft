
resource "aws_lb" "bboys-alb" {
    name = "bboys-alb"
    internal = "false"
    load_balancer_type = "application"
    security_groups = [aws_security_group.bboys-elb-sg.id]
    subnets = [for subnet in aws_subnet.public : subnet.id ]
    drop_invalid_header_fields = true
    
    tags = {
        Name = "${var.default_tags.env}-ALB"
    }
}

resource "aws_lb_target_group" "ec2-tg" {
    name = "bboys-ec2-tg"
    port = 443
    protocol = "HTTPS"
    target_type = "instance"
    vpc_id = aws_vpc.bboys-vpc.id
    health_check {
      enabled = "true"
      healthy_threshold = 2
      interval = 30
      port = 80
      protocol = "HTTP"
      timeout = 20
      unhealthy_threshold = 5
      path = "/"



    }

}

resource "aws_lb_listener" "bboys-443-listener" {
    load_balancer_arn = aws_lb.bboys-alb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = aws_iam_server_certificate.alb-cert.arn
     default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.ec2-tg.arn
        }
        depends_on = [
          aws_lb.bboys-alb,
          aws_iam_server_certificate.alb-cert
        ]
}

resource "aws_autoscaling_group" "bboys-asg" {
    name = "BBOYS-ASG"
    max_size = 2
    min_size = 2
    desired_capacity = 2
    health_check_grace_period = 360
    default_instance_warmup = 360
    health_check_type = "ELB"
vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
    launch_template {
        id = aws_launch_template.bboys-ec2-launch-template.id
        version = "$Latest"
    }
    
    target_group_arns = [aws_lb_target_group.ec2-tg.arn]
depends_on = [
    aws_lb.bboys-alb,
    aws_launch_template.bboys-ec2-launch-template

]
}

resource "aws_lb_listener_certificate" "alb-cert" {
    listener_arn = aws_lb_listener.bboys-443-listener.arn
    certificate_arn = aws_iam_server_certificate.alb-cert.arn
  
}