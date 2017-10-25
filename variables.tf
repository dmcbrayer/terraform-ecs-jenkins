variable "access_key" {
  description = "The AWS access key."
}

variable "secret_key" {
  description = "The AWS secret key."
}

variable "region" {
  description = "The AWS region to create resources in."
  default = "us-east-1"
}

variable "availability_zone" {
  description = "The availability zone"
  default = "us-east-1b"
}

variable "ecs_cluster_name" {
  description = "The name of the Amazon ECS cluster."
  default = "jenkins"
}

variable "amis" {
  description = "Which AMI to spawn. Defaults to the AWS ECS optimized images."
  default = {
    us-east-1 = "ami-ec33cc96"
    us-east-2 = "ami-34032e51"
    us-west-1 = "ami-d5d0e0b5"
    us-west-2 = "ami-29f80351"
  }
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "min_instance_size" {
  default = 1
  description = "Minimum number of EC2 instances."
}

variable "max_instance_size" {
  default = 2
  description = "Maximum number of EC2 instances."
}

variable "desired_instance_capacity" {
  default = 1
  description = "Desired number of EC2 instances."
}

variable "desired_service_count" {
  default = 1
  description = "Desired number of ECS services."
}

variable "s3_bucket" {
  default = "blast-jenkins"
  description = "S3 bucket where remote state and Jenkins data will be stored."
}

variable "restore_backup" {
  default = false
  description = "Whether or not to restore Jenkins backup."
}

