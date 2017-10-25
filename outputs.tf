output "elb_dns_name" {
  value = "${aws_elb.lb_jenkins.dns_name}"
}