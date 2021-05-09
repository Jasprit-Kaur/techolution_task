provider "aws" {
  region     = "ap-south-1"
  profile    = "jkaur"
}

resource "tls_private_key" "privatekeytask" {
  algorithm   = "RSA"
}

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = tls_private_key.privatekeytask.public_key_openssh
}

resource "aws_vpc" "vpc_task" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_task"
  }
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc_task
  ]

  vpc_id     = aws_vpc.vpc_task.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_internet_gateway" "gw_task" {
  vpc_id = aws_vpc.vpc_task.id

  tags = {
    Name = "gw_task"
  }
 depends_on = [
    aws_vpc.vpc_task
  ]
}

resource "aws_route_table" "route_task" {
  vpc_id = aws_vpc.vpc_task.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_task.id
  }

tags = {
    Name = "route_task"
  }
 depends_on = [
    aws_internet_gateway.gw_task
  ]
}

resource "aws_route_table_association" "asso_task" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_task.id
  depends_on = [
    aws_route_table.route_task
  ]
}

resource "aws_eip" "task_eip" {
   vpc = true
}

resource "aws_nat_gateway" "nat_task" {
  allocation_id = aws_eip.task_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat_task"
  }
   depends_on = [
     aws_eip.task_eip
   ]

}

resource "aws_route_table" "route_task_sec" {
  vpc_id = aws_vpc.vpc_task.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_task.id
  }

tags = {
    Name = "route_task_sec"
  }  
  depends_on = [
    aws_nat_gateway.nat_task
  ]
}


resource "aws_security_group" "securitygroup2" {
  name        = "securitygroup2"
  description = "Allow HTTP and SSH and NFS"
  vpc_id      = aws_vpc.vpc_task.id


  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "securitygroup2"
  }
}


resource "aws_instance" "task_wp" {

  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "key"
  vpc_security_group_ids = [aws_security_group.securitygroup2.id]
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "task_wp"
  }
}

output "public_ip" {
value = aws_instance.task_wp.public_ip
}

