variable "020cba7c55df1f615b0c1f2d3e4a5b6" {
  description = "This variable is used to store the unique identifier for the resource."
  type        = string
  default     = "default_value"
  
}
variable "aws_instance_ami" {
  description = "The AMI to use for the AWS instance."
  type        = string
  default     = "ami-020cba7c55df1f615"
  
}

variable "aws_instance_type" {
  description = "The type of instance to use for the AWS instance."
  type        = string
  default     = "t2.micro"
  
}   

variable "aws_region" {
  description = "The AWS region to deploy the instance in."
  type        = string
  default     = "us-east-1"
  
}

variable "aws_instance_key_name" {
  description = "The name of the key pair to use for the AWS instance."
  type        = string
  default     = "my-key-pair"
  
}

variable "cidr_block" {
    description = "The CIDR block for the VPC."
    type        = string
    default     = "10.0.0.0/16"
  
}

variable "public_subnet_cidr_block" {
    description = "The CIDR block for the subnet."
    type        = string
    default     = "10.0.1.0/24"
}

variable "vpc_name" {
    description = "The name of the VPC."
    type        = string
    default     = "main_vpc"
}
variable "public_subnet_name_nginx1" {
    description = "The name of the public subnet."
    type        = string
    default     = "10.0.2.0/24"



}

variable "subnet_name_nginx2" {
    description = "The name of the second public subnet."
    type        = string
    default     = "10.0.3.0/24"
  
}

variable "subnet_name_mysql" {
    description = "The name of the third public subnet."
    type        = string
    default     = "10.0.4.0/24"
    
  
}