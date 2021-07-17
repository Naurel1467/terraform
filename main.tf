provider "aws" {
    region = "us-east-1"
    profile = "default"
}

#vpc
resource "aws_vpc" "vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
        Name = "myvpc"
    }
}

#security_groups_for public ec2

resource "aws_security_group" "public_sg" {
  name        = "public security group"
  description = "Allow traffic outside"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description      = "from my Ip"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["#####/32"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  
  ingress {
    description      = "from my Ip"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["####/32"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "priavte_sg"
  description = "Allow traffic outside"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description      = "from my Ip"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.1.0.0/16"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

#public_subnet
resource "aws_subnet" "subnet_public" {
    cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = "true"

    tags = {
      "Name" = "sub-public"
    }
}

#private_subnet
resource "aws_subnet" "subnet_private" {    
    cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = "true"

    tags = {
      "Name" = "sub-private"
    }
  
}

#IGW_public
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags = {
      "Name" = "igw"
    }
  
}

resource "aws_eip" "eip" {
  vpc      = true
  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id     = "${aws_subnet.subnet_public.id}"
  

  tags = {
    "Name" = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

#route-table_public
resource "aws_route_table" "route_public" {
    vpc_id = "${aws_vpc.vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
  tags = {
    "Name" = "route-public"
  }
}
#route-table private
resource "aws_route_table" "route_private" {
    vpc_id = "${aws_vpc.vpc.id}"
    depends_on = [aws_nat_gateway.nat]

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }

    tags = {
        "Name" = "route-private"
    } 
}

#route table association public subnet
resource "aws_route_table_association" "route_assoc1" {
    subnet_id = "${aws_subnet.subnet_public.id}"
    route_table_id = "${aws_route_table.route_public.id}"  
}

#route table association priavte subnet
resource "aws_route_table_association" "route-assoc2" {
    subnet_id = "${aws_subnet.subnet_private.id}"
    route_table_id = "${aws_route_table.route_private.id}"
    #nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

#key_pairs
/*resource "aws_key_pair" "terr-key" {
  key_name = "terra-key"
  public_key = "${file(C/Users/ravit/Downloads/terra-key)}"
}*/


#public instance
resource "aws_instance" "public-inst" { 
    count = length(var.counter)   
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    key_name = "terra-key"
    subnet_id = "${aws_subnet.subnet_public.id}"
    vpc_security_group_ids = ["${aws_security_group.public_sg.id}"]

    tags = {
        #"Name" = "${format("web-%03d", count.index + 1)}"
       # Name = "${var.counter[count.index]}${count.index + 1}" #raviteja1 laxmi2 ammayi3  
      # Name = "${element(var.counter, count.index)}${count.index + 1}"  #raviteja1 laxmi2 ammayi3 
    }
  
}

#private_instance
/*resource "aws_instance" "private-inst" {
    ami= "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    key_name = "terra-key"
    subnet_id = "${aws_subnet.subnet_private.id}" 
    vpc_security_group_ids = [ "${aws_security_group.private_sg.id}" ]
}

output "instance_pub" {
  value = aws_instance.private-inst.private_ip
}*/