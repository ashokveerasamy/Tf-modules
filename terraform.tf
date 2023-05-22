#Creating EC2  instance with security group, VPC,2-Subnets,IGW, Route table, App Load balance with target instance, IAM user group added User with S3full permission. 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# VPC configuration
resource "aws_vpc" "newvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# Security Group configuration
resource "aws_security_group" "newalltcp" {
  name_prefix = "alltcp-security-group"
  description = "alltcp Security Group"
  vpc_id      = aws_vpc.newvpc.id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alltcp-security-group"
  }
}
# Subnet configuration
resource "aws_subnet" "newsubnet" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "my-subnet"
}  
}
# Subnet configuration
resource "aws_subnet" "newsubnet2" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "my-subnet2"
  }

}
# Internet Gateway configuration
resource "aws_internet_gateway" "newigw" {
  vpc_id = aws_vpc.newvpc.id

  tags = {
    Name = "my-igw"
  }
}

# Route Table configuration
resource "aws_route_table" "new-route" {
  vpc_id = aws_vpc.newvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.newigw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

# Route Table Association configuration
resource "aws_route_table_association" "example" {
  subnet_id = aws_subnet.newsubnet.id  
  route_table_id = aws_route_table.new-route.id
}
# Route Table Association configuration
resource "aws_route_table_association" "example2" {
  subnet_id = aws_subnet.newsubnet2.id
  route_table_id = aws_route_table.new-route.id
}
# ALB configuration
resource "aws_lb" "app-lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"

  subnets = [aws_subnet.newsubnet.id, aws_subnet.newsubnet2.id]

  security_groups = [aws_security_group.newalltcp.id]

  tags = {
    Name = "app-load-balancer"
  }
}

# ALB listener configuration
resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.app-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb-target.arn
  }
}
# ALB target group configuration
resource "aws_lb_target_group" "lb-target" {
  name        = "lb-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path = "/healthcheck"
  }

  vpc_id = aws_vpc.newvpc.id

  tags = {
    Name = "lb-target-group"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-038face4e75b6a399" # ap-south-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.newsubnet.id
  key_name = "Mylaptop_10022023"
  security_groups    = [aws_security_group.newalltcp.id]
  associate_public_ip_address = true
  user_data     = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3-pip
  EOF
   tags = {
    Name = "New World"
   }
}
# ALB target group attachment
resource "aws_lb_target_group_attachment" "lbtarget-Attach" {
  target_group_arn = aws_lb_target_group.lb-target.arn
  target_id        = aws_instance.web.id
  port             = 80
}
resource "aws_iam_group" "ashok" {
  name = "dev-group"
}

resource "aws_iam_user" "ashok" {
  name = "ashok-user"
  path = "/"
}
resource "aws_iam_user_policy_attachment" "attach-test" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  user       = aws_iam_user.ashok.name
}
resource "aws_iam_user_group_membership" "add-group" {
  user = aws_iam_user.ashok.name
  groups = [
    aws_iam_group.ashok.name,]
}

