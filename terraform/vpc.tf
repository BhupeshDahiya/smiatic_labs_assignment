resource "aws_vpc" "argocd_sandbox" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  # Required for EKS and private node communication
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "argocd_sandbox-vpc"
  }
}

# making only 2 private and 2 public subnet for demonstration purposes
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.argocd_sandbox.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name                     = "argocd_sandbox-public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.argocd_sandbox.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1d"

  tags = {
    Name                     = "argocd_sandbox-public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.argocd_sandbox.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                              = "argocd_sandbox-private"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.argocd_sandbox.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name                              = "argocd_sandbox-private"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.argocd_sandbox.id

  tags = {
    Name = "argocd_sandbox igw"
  }
}

# Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "argocd_sandbox NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# Public rt 

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.argocd_sandbox.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "argocd_sandbox-pub-rt"
  }
}

# Private rt

resource "aws_route_table" "pvt_rt" {
  vpc_id = aws_vpc.argocd_sandbox.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "argocd_sandbox-pvt-rt"
  }
}

resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pvt" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.pvt_rt.id
}

resource "aws_route_table_association" "pvt_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.pvt_rt.id
}

output "vpc_id" {
  value = aws_vpc.argocd_sandbox.id
}

output "pub_sub" {
  value = aws_subnet.public.id
}

output "pub_sub" {
  value = aws_subnet.public_2.id
}


output "pvt_sub_2" {
  value = aws_subnet.private_2.id

  # forcing Terraform to hold back any instance using this subnet
  # until the NAT Gateway and Route Table Mappings are 100% complete!
  # had to do this because pvt subnet gets created relatively faster than the nat gateway and thus EC2 just picks up this 
  # pvt subnet and starts the bootstrap script which requires internet connection via NAT gateway and fails if it cant connect
  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.pvt,
    aws_route_table_association.pvt_2
  ]
}

output "pvt_sub" {
  value = aws_subnet.private.id

  # forcing Terraform to hold back any instance using this subnet
  # until the NAT Gateway and Route Table Mappings are 100% complete!
  # had to do this because pvt subnet gets created relatively faster than the nat gateway and thus EC2 just picks up this 
  # pvt subnet and starts the bootstrap script which requires internet connection via NAT gateway and fails if it cant connect
  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.pvt,
    aws_route_table_association.pvt_2
  ]
}