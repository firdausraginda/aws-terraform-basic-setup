resource "aws_subnet" "default_ap_southeast_1c" {
  vpc_id                  = var.default_vpc_id
  cidr_block              = "172.31.16.0/20"
  map_public_ip_on_launch = true
}
