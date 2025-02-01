

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "blog_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-1a", "us-west-1b", "us-west-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  tags = {
    Terraform = "true"
    Environment = "dev"
  }
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



module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.0.1"

  name = "web"

  max_size = 2
  min_size = 1
  
  image_id          = data.aws_ami.app_ami.id
  instance_type     = "t3.micro"

  security_groups           = [module.blog_sg.security_group_id]
  vpc_zone_identifier       =  module.blog_vpc.public_subnets
  target_groups = {
    "ex-instance" = {
      target_group_arn = module.blog_alb.target_groups["ex-instance"].arn
    }
  }

}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "blog_sg"
  description = "Security group for web-server with HTTP ports open within VPC"

  vpc_id = module.blog_vpc.vpc_id

  ingress_rules           = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks     = ["0.0.0.0/0"]
  egress_rules            = ["all-all"]
  egress_cidr_blocks      = ["0.0.0.0/0"]
}

module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name              = "blog_alb"
  vpc_id            = module.blog_vpc.vpc_id
  subnets           = module.blog_vpc.public_subnets
  security_groups   = [module.blog_sg.security_group_id]
 

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix      = "h1"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}