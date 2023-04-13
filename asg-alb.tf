
resource "aws_lb" "jd-alb" {
    name = "jd-alb"
    internal = "false"
    load_balancer_type = "application"
    security_groups = [aws_security_group.jd-elb-sg.id]
    subnets = [for subnet in aws_subnet.public : subnet.id ]

    
    tags = {
        Name = "${var.default_tags.env}-ALB"
    }
}

resource "aws_lb_target_group" "ec2-tg" {
    name = "jd-ec2-tg"
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = aws_vpc.jd-vpc-test.id
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

resource "aws_lb_listener" "jd-80-listener" {
    load_balancer_arn = aws_lb.jd-alb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.ec2-tg.arn
        }
}

resource "aws_autoscaling_group" "jd-asg" {
    name = "JD-ASG"
    max_size = 2
    min_size = 2
    desired_capacity = 2
    health_check_grace_period = 360
    default_instance_warmup = 360
    health_check_type = "ELB"
vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
    launch_template {
        id = aws_launch_template.jd-ec2-launch-template.id
        version = "$Latest"
    }
    
    target_group_arns = [aws_lb_target_group.ec2-tg.arn]
depends_on = [
    aws_lb.jd-alb,
    aws_launch_template.jd-ec2-launch-template

]
}