
variable "web_port" {
  description = "The port on which the web servers listen for connections"
  default = 80
}

variable "web_instance_type" {
  description = "The EC2 instance type for the web servers"
  default = "t2.micro"
}

variable "web_autoscale_min_size" {
  description = "The fewest amount of EC2 instances to start"
  default = 2
}

variable "web_autoscale_max_size" {
  description = "The largest amount of EC2 instances to start"
  default = 3
}




resource "aws_security_group" "web" {
  name = "${format("%s-web-sg", var.name)}"

  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port   = "${var.web_port}"
    to_port     = "${var.web_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "65535"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Group = "${var.name}"
  }

}

#TODO REMOVE
resource "aws_key_pair" "web-key" {
  key_name = "web-key"
  public_key = "${var.public_key}"

}

resource "aws_launch_configuration" "web" {
  image_id        = "${data.aws_ami.amazon_linux.id}"
  instance_type   = "${var.web_instance_type}"
  security_groups = ["${aws_security_group.web.id}"]
  key_name = "web-key"
  name_prefix = "${var.name}-web-vm-"

  user_data = <<-EOF
              #!/bin/bash
              # install git/nginx
              # in this userdata section..install git/nginx, configure the files related to nginx..and deploy the app(web)
              #also run prometheus exporter here..so that prometheus can take metrics and display on grafana
              #${file("./script/prometheus_node_exporter_setup.sh")}
              EOF

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "web" {
  launch_configuration = "${aws_launch_configuration.web.id}"

  vpc_zone_identifier = ["${module.vpc.public_subnets}"]

  load_balancers    = ["${module.elb_web.this_elb_name}"]
  health_check_type = "EC2"

  min_size = "${var.web_autoscale_min_size}"
  max_size = "${var.web_autoscale_max_size}"

  tags {
    key = "Group" 
    value = "${var.name}"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "scale-up-cpu-policy-web" {
name = "scale-up-cpu-policy-web"
autoscaling_group_name = "${aws_autoscaling_group.web.name}"
adjustment_type = "ChangeInCapacity"
step_adjustment = [
    {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 50
      scaling_adjustment          = 1
    }
  ]
}

resource "aws_autoscaling_policy" "scaledown-cpu-policy-web" {
name = "scaledown-cpu-policy-web"
autoscaling_group_name = "${aws_autoscaling_group.web.name}"
adjustment_type = "ChangeInCapacity"
step_adjustment = [
    {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  ]
}
