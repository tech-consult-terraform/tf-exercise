# main.tf

# VPC with 3 public subnet in available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}



# Define AMI for instance
data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]
}

# Configure launch template (to specify the EC2 instance configuration that an ASG will use to launch each new instance)
resource "aws_launch_template" "my_launch_template" {
    name_prefix            = "fariha-lt"
        # name prefix to use for all versions of this launch configuration - Terraform will append a unique identifier to the prefix for each launch configuration created

    image_id        = data.aws_ami.amazon-linux.id
        # Amazon Linux AMI specified by a data source (data source from line 23)

    instance_type = "t3.micro"
        # instance type

    user_data       = filebase64("${path.module}/user-data.sh")

        # file("user-data.sh")
        # user data script - configures the instances to run the user-data.sh file in this repository at launch time

    vpc_security_group_ids = ["${aws_security_group.terramino_instance.id}"]
        # allows ingress traffic on port 80 and egress traffic to all endpoints

    lifecycle { # lifecycle block = use to avoid unwanted scaling of your ASG
        create_before_destroy = true
            # Why use lifecyle block?
                # bc you cannot modify a launch configuration, so any changes to the definition force Terraform to create a new resource. create_before_destroy argument in the lifecycle block instructs Terraform to create the new version before destroying the original to avoid any service interruptions
                # use Terraform lifecycle arguments to avoid drift or accidental changes - since ASGs are dynamic and Terraform does not manage the underlying instances directly because every scaling action would introduce state drift. 
    }
}

# ASG configuration
resource "aws_autoscaling_group" "terramino" {
  name                 = "terramino"
  min_size             = 2
  max_size             = 3
  desired_capacity     = 2
  
  launch_template { # Launch Template
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier  = module.vpc.public_subnets
    # the subnets where the ASGs will launch new instances

  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "fariha_tf"
    propagate_at_launch = true
  }
}


# Create an application load balancer
resource "aws_lb" "terramino" {
  name               = "fariha-asg-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terramino_lb.id]
  subnets            = module.vpc.public_subnets
}

# Specify how to handle any HTTP requests to port 80 = aka forward all requests to the load balancer to a target group. 
resource "aws_lb_listener" "terramino" {
  load_balancer_arn = aws_lb.terramino.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terramino.arn
  }
}

# Target group configuration - defines the collection of instances our ALB will send traffic to (TF does not manage the configuration of the targets in that group directly, but instead specifies a list of destinations the load balancer can forward requests to).
resource "aws_lb_target_group" "terramino" {
  name     = "fariha-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}


# aws_autoscaling_attachment resource links your ASG with the target group - allows AWS to automatically add/remove instances from the target group over their lifecycle.
resource "aws_autoscaling_attachment" "terramino" {
  autoscaling_group_name = aws_autoscaling_group.terramino.id
  lb_target_group_arn   = aws_lb_target_group.terramino.arn
}

# Security Group for ASG EC2 instances
resource "aws_security_group" "terramino_instance" {
  name = "learn-asg-terramino-instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.terramino_lb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

# Security Group for Load Balancer 
resource "aws_security_group" "terramino_lb" {
  name = "learn-asg-terramino-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}
