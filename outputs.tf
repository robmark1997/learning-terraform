output "instance_ami" {
  value = aws_instance.web.ami
}

output "instance_arn" {
  value = aws_instance.web.arn
}

output "vpc_name"{
  value = data.aws_vpc.default.id
}
