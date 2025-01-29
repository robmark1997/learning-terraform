

data "aws_vpc" "default" {
  default = true
}


data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.blog.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}

module "blog-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "blog-sg"
  description = "Security group for web-server with HTTP ports open within VPC"

  vpc_id = data.aws_vpc.default.id

  ingress_rules           = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks     = ["0.0.0.0/0"]
  egress_rules            = ["all-all"]
  egress_cidr_blocks      = ["0.0.0.0/0"]
}
