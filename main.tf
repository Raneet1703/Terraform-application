#VPC Creation
resource "aws_vpc" "custom_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

#Subnet Creation
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.custom_vpc.id

  cidr_block              = "10.0.0.0/24"
  availability_zone       = data.aws_availability_zones.available_1.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.custom_vpc.id

  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available_1.names[1]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.custom_vpc.id
}

# Route Table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                              # All outbound traffic
    gateway_id = aws_internet_gateway.internet_gateway.id # Route to the internet gateway
  }
}

resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = aws_subnet.public_subnet_1.id # Update to the correct subnet
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = aws_subnet.public_subnet_2.id # Update to the correct subnet
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "mysg" {
  name_prefix = "web"
  vpc_id      = aws_vpc.custom_vpc.id

  # Inbound rules (allow traffic)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access from anywhere
  }

  # Outbound rules (allow traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic to anywhere
  }

  tags = {
    Name = "Web-sg"
  }

}

# resource "aws_s3_bucket" "new_bucket" {
#   bucket = "kyakarogejankelala"
# }

# resource "aws_s3_bucket_ownership_controls" "mybucketownership" {
#   bucket = aws_s3_bucket.new_bucket.id

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "public_access" {
#   bucket = aws_s3_bucket.new_bucket.id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# resource "aws_s3_bucket_acl" "example" {
#   depends_on = [
#     aws_s3_bucket_ownership_controls.mybucketownership,
#     aws_s3_bucket_public_access_block.public_access,
#   ]

#   bucket = aws_s3_bucket.new_bucket.id
#   acl    = "public-read"
# }

resource "aws_instance" "web" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.public_subnet_1.id
  user_data              = base64encode(file("userdata.sh"))
}

resource "aws_instance" "web2" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.public_subnet_2.id
  user_data              = base64encode(file("userdatanew.sh"))
}

# resource "aws_lb" "mylb" {
#   internal = false
#   load_balancer_type = "application"

#   security_groups = [aws_security_group.mysg.id]
# }

resource "aws_lb" "app_lb" {
  name               = "my-lb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.mysg.id]
  subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "web"
  }

}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "tgattach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tgattach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}