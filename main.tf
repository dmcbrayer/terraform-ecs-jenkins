provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

data "aws_availability_zones" "all" {}

resource "aws_vpc" "jenkins" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    for = "${var.ecs_cluster_name}"
  }
}

resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.jenkins.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jenkins.id}"
  }

  tags {
    for = "${var.ecs_cluster_name}"
  }
}

resource "aws_route_table_association" "external-jenkins" {
  subnet_id = "${aws_subnet.jenkins.id}"
  route_table_id = "${aws_route_table.external.id}"
}

resource "aws_subnet" "jenkins" {
  vpc_id = "${aws_vpc.jenkins.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.availability_zone}"

  tags {
    for = "${var.ecs_cluster_name}"
  }
}

resource "aws_internet_gateway" "jenkins" {
  vpc_id = "${aws_vpc.jenkins.id}"

  tags {
    for = "${var.ecs_cluster_name}"
  }
}

resource "aws_security_group" "sg_jenkins" {
  name = "sg_${var.ecs_cluster_name}"
  description = "Allows traffic from ssh and the load balancer SG"
  vpc_id = "${aws_vpc.jenkins.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.sg_load_balancer.id}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.sg_load_balancer.id}"]
  }

  ingress {
    from_port = 50000
    to_port = 50000
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "sg_load_balancer" {
  name = "sg_${var.ecs_cluster_name}_lb"
  description = "Allows ssl web traffic"
  vpc_id = "${aws_vpc.jenkins.id}"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_ecs_cluster" "jenkins" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_autoscaling_group" "asg_jenkins" {
  name = "asg_${var.ecs_cluster_name}"

  availability_zones = ["${var.availability_zone}"]
  min_size = "${var.min_instance_size}"
  max_size = "${var.max_instance_size}"
  desired_capacity = "${var.desired_instance_capacity}"

  launch_configuration = "${aws_launch_configuration.lc_jenkins.name}"
  vpc_zone_identifier = ["${aws_subnet.jenkins.id}"]

  load_balancers = ["${aws_elb.lb_jenkins.name}"]
  health_check_type = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "${var.ecs_cluster_name}_asg"
    propagate_at_launch = true
  }
}

data "template_file" "user_data" {
  template = "${file("templates/user_data.tpl")}"

  vars {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    s3_bucket = "${var.s3_bucket}"
    ecs_cluster_name = "${var.ecs_cluster_name}"
    restore_backup = "${var.restore_backup}"
  }
}

resource "aws_launch_configuration" "lc_jenkins" {
  name_prefix = "lc_${var.ecs_cluster_name}-"
  image_id = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.sg_jenkins.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.iam_instance_profile.name}"
  key_name = "${var.key_name}"
  associate_public_ip_address = true
  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "lb_jenkins" {
  name = "elb-${var.ecs_cluster_name}"
  security_groups = ["${aws_security_group.sg_load_balancer.id}"]
  subnets = ["${aws_subnet.jenkins.id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/login"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-1:527214449657:certificate/7edd805a-3249-4a93-9f1b-18820a3cf595"
  }
}

resource "aws_iam_role" "host_role_jenkins" {
  name = "host_role_${var.ecs_cluster_name}"
  assume_role_policy = "${file("policies/ecs-role.json")}"
}

resource "aws_iam_role_policy" "instance_role_policy_jenkins" {
  name = "instance_role_policy_${var.ecs_cluster_name}"
  policy = "${file("policies/ecs-instance-role-policy.json")}"
  role = "${aws_iam_role.host_role_jenkins.id}"
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "iam_instance_profile_${var.ecs_cluster_name}"
  path = "/"
  role = "${aws_iam_role.host_role_jenkins.name}"
}
