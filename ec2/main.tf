resource "aws_instance" "airflow_test" {
  ami                         = "ami-08d59269edddde222"
  associate_public_ip_address = true
  availability_zone           = "ap-southeast-1b"
  instance_type               = "t3.small"
  subnet_id                   = "subnet-0e59d3063249f2a7c"
  vpc_security_group_ids      = ["sg-0d9f119fee4b9bb33"]
  iam_instance_profile        = var.iam_instance_profile

  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  tags = {
    Name = "airflow-test-ec2"
  }
}
