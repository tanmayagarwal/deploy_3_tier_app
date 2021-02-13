resource "aws_instance" "prometheus-1" {
  ami = "${data.aws_ami.amazon_linux.id}"
  instance_type = "t2.small"
  key_name = "web-key"
  count = 1
  vpc_security_group_ids = ["${aws_security_group.elb_app.id}"]
  subnet_id = element(var.vpc_private_subnets,0)
  associate_public_ip_address = true
  tags {
    Name = "prometheus-1"
    Terraform = "true"
  } 
}


# Configure prometheus
resource "null_resource" "prometheus-1" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.prometheus-1.public_ip}"
    private_key = "${file("${var.public_key}")}"
  }

  # We need the prometheus instance first
  # We don't need other instances up first because we are using EC2 service discovery
  depends_on = [ "aws_instance.prometheus-1" ]

  # Provision the Prometheus configuration script
  provisioner "file" {
    source = "scripts/full_prometheus_setup.sh"
    destination = "/tmp/full_prometheus_setup.sh"
  }

  # Execute Prometheus configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.region}'\" >> ~/.profile",
      "chmod +x /tmp/full_prometheus_setup.sh",
      "bash /tmp/full_prometheus_setup.sh '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}' '${var.region}' '1'",
    ]
  }
}


# Provision Grafana
resource "null_resource" "grafana-1" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"    
    host = "${aws_instance.prometheus-1.public_ip}"
    private_key = "${file("${var.private_key}")}"
  }

  # We need Prometheus and Grafana installed first
  depends_on = [ "null_resource.prometheus-1" ]

  # Provision the Grafana datasource file
  provisioner "file" {
    source = "scripts/datasource-prometheus.yaml"
    destination = "/tmp/datasource-prometheus.yaml"
  }

  # Provision the Grafana dashboard file
  provisioner "file" {
    source = "scripts/dashboards.yaml"
    destination = "/tmp/dashboards.yaml"
  }

  # Provision the Grafana dashboard JSON file
  provisioner "file" {
    source = "scripts/dashboards.json"
    destination = "/tmp/dashboards.json"
  }

  # Move Grafina remotely
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/datasource-prometheus.yaml /etc/grafana/provisioning/datasources/",
      "sudo mv /tmp/dashboards.yaml /etc/grafana/provisioning/dashboards/",
      "sudo mkdir /var/lib/grafana/dashboards",
      "sudo mv /tmp/dashboards.json /var/lib/grafana/dashboards/",
      "sudo systemctl restart grafana-server.service",
    ]
  }
}




resource "aws_instance" "prometheus-2" {
  ami = "${data.aws_ami.amazon_linux.id}"
  instance_type = "t2.small"
  key_name = "web-key"
  count = 1
  vpc_security_group_ids = ["${aws_security_group.elb_app.id}"]
  subnet_id = element(var.vpc_private_subnets,1)
  associate_public_ip_address = true
  tags {
    Name = "prometheus-2"
    Terraform = "true"
  } 
}

# Configure prometheus
resource "null_resource" "prometheus-2" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.prometheus-2.public_ip}"
    private_key = "${file("${var.private_key}")}"
  }

  # We need the prometheus instance first
  # We don't need other instances up first because we are using EC2 service discovery
  depends_on = [ "aws_instance.prometheus-2" ]

  # Provision the Prometheus configuration script
  provisioner "file" {
    source = "scripts/full_prometheus_setup.sh"
    destination = "/tmp/full_prometheus_setup.sh"
  }

  # Execute Prometheus configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.region}'\" >> ~/.profile",
      "chmod +x /tmp/full_prometheus_setup.sh",
      "bash /tmp/full_prometheus_setup.sh '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}' '${var.region}' '2'",
    ]
  }
}

# Provision Grafana
resource "null_resource" "grafana-2" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"    
    host = "${aws_instance.prometheus-2.public_ip}"
    private_key = "${file("${var.private_key}")}"
  }

  # We need Prometheus and Grafana installed first
  depends_on = [ "null_resource.prometheus-2" ]

  # Provision the Grafana datasource file
  provisioner "file" {
    source = "scripts/datasource-prometheus.yaml"
    destination = "/tmp/datasource-prometheus.yaml"
  }

  # Provision the Grafana dashboard file
  provisioner "file" {
    source = "scripts/dashboards.yaml"
    destination = "/tmp/dashboards.yaml"
  }

  # Provision the Grafana dashboard JSON file
  provisioner "file" {
    source = "scripts/dashboards.json"
    destination = "/tmp/dashboards.json"
  }

  # Move Grafina remotely
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/datasource-prometheus.yaml /etc/grafana/provisioning/datasources/",
      "sudo mv /tmp/dashboards.yaml /etc/grafana/provisioning/dashboards/",
      "sudo mkdir /var/lib/grafana/dashboards",
      "sudo mv /tmp/dashboards.json /var/lib/grafana/dashboards/",
      "sudo systemctl restart grafana-server.service",
    ]
  }
}
