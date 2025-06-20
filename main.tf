# -------- VPC & Subnets --------
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_name
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_block
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "nginx1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_name_nginx1
    map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = { Name = "nginx-subnet-1" }
}

resource "aws_subnet" "nginx2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_name_nginx2
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags = { Name = "nginx-subnet-2" }
}

resource "aws_subnet" "mysql" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_name_mysql
  availability_zone = "us-east-1a"
  tags = { Name = "mysql-subnet" }
}

# -------- Internet Gateway & Routing --------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.nginx1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.nginx2.id
  route_table_id = aws_route_table.public.id
}
# -------- Security Groups --------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from Internet"
  vpc_id      = aws_vpc.main.id

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
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = { Name = "nginx-sg" }
    
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow MySQL from VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------- EC2 Instances --------
resource "aws_instance" "nginx1" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.nginx1.id
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # Create custom index.html
    echo '<html>
    <head><title>Nginx2 Landing Page</title></head>
    <body style="font-family: Arial; text-align: center; margin-top: 50px;">
        <h1>Welcome to Nginx2</h1>
        <p>This is the custom landing page for Nginx server 2.</p>
    </body>
    </html>' | sudo tee /usr/share/nginx/html/index.html

  EOF

  tags = { Name = "nginx1" }
}

resource "aws_instance" "nginx2" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.nginx2.id
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
   #!/bin/bash
    sudo apt update -y
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # Create custom index.html
    echo '<html>
    <head><title>Nginx1 Landing Page</title></head>
    <body style="font-family: Arial; text-align: center; margin-top: 50px;">
        <h1>Welcome to Nginx1</h1>
        <p>This is the custom landing page for Nginx server 1.</p>
    </body>
    </html>' | sudo tee /usr/share/nginx/html/index.html
        EOF

  tags = { Name = "nginx2" }
}

resource "aws_instance" "mysql" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.mysql.id
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt  update -y
    sudo apt install -y mysql-server
    sudo systemctl enable mysqld
    sudo systemctl start mysqld
  EOF

  tags = { Name = "mysql" }
}

# -------- Application Load Balancer --------
resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.nginx1.id, aws_subnet.nginx2.id]
}

resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "nginx1_tg_attachment" {
  target_group_arn = aws_lb_target_group.nginx_tg.arn
  target_id        = aws_instance.nginx1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "nginx2_tg_attachment" {
  target_group_arn = aws_lb_target_group.nginx_tg.arn
  target_id        = aws_instance.nginx2.id
  port             = 80
}

# -------- Internal NLB for MySQL --------
resource "aws_lb" "internal_nlb" {
  name               = "internalnlb"  # Required fix
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.mysql.id]
}

resource "aws_lb_target_group" "mysql_tg" {
  name        = "mysql-target"
  port        = 3306
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_listener" "mysql_listener" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 3306
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mysql_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "mysql_tg_attachment" {
  target_group_arn = aws_lb_target_group.mysql_tg.arn
  target_id        = aws_instance.mysql.id
  port             = 3306
}

# -------- Outputs --------
output "alb_dns_name" {
  value = aws_lb.frontend_alb.dns_name
}

output "nlb_dns_name" {
  value = aws_lb.internal_nlb.dns_name
}
output "nginx1_public_ip" {
  value = aws_instance.nginx1.public_ip
}