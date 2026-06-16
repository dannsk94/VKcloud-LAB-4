# Внешняя сеть для Floating IP
data "vkcs_networking_network" "external" {
  name = "internet"
}

# Существующий роутер
data "vkcs_networking_router" "existing_router" {
  name = "router_4389"
}

# VPC (сеть)
resource "vkcs_networking_network" "vpc" {
  name           = "${var.project_name}-vpc"
  admin_state_up = true
}

# Публичная подсеть (бастион + LB)
resource "vkcs_networking_subnet" "public" {
  name        = "${var.project_name}-public-subnet"
  network_id  = vkcs_networking_network.vpc.id
  cidr        = "192.168.1.0/24"
  enable_dhcp = true

  allocation_pool {
    start = "192.168.1.10"
    end   = "192.168.1.200"
  }
}

# Приватная подсеть (веб-серверы + БД)
resource "vkcs_networking_subnet" "private" {
  name        = "${var.project_name}-private-subnet"
  network_id  = vkcs_networking_network.vpc.id
  cidr        = "192.168.2.0/24"
  enable_dhcp = true
}

# Подключение подсетей к роутеру
resource "vkcs_networking_router_interface" "public" {
  router_id = data.vkcs_networking_router.existing_router.id
  subnet_id = vkcs_networking_subnet.public.id
}

resource "vkcs_networking_router_interface" "private" {
  router_id = data.vkcs_networking_router.existing_router.id
  subnet_id = vkcs_networking_subnet.private.id
}

# Security Group для бастиона
resource "vkcs_networking_secgroup" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion host security group"
}

resource "vkcs_networking_secgroup_rule" "bastion_ssh_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.my_ip
  security_group_id = vkcs_networking_secgroup.bastion_sg.id
}

# Security Group для веб-серверов
resource "vkcs_networking_secgroup" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
}

resource "vkcs_networking_secgroup_rule" "web_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "192.168.1.0/24"
  security_group_id = vkcs_networking_secgroup.web_sg.id
}

resource "vkcs_networking_secgroup_rule" "web_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.web_sg.id
}

resource "vkcs_networking_secgroup_rule" "web_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.web_sg.id
}

# Security Group для базы данных
resource "vkcs_networking_secgroup" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database"
}

resource "vkcs_networking_secgroup_rule" "db_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "192.168.2.0/24"
  security_group_id = vkcs_networking_secgroup.db_sg.id
}

resource "vkcs_networking_secgroup_rule" "db_postgres" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = "192.168.2.0/24"
  security_group_id = vkcs_networking_secgroup.db_sg.id
}

# Security Group для балансировщика
resource "vkcs_networking_secgroup" "lb_sg" {
  name        = "${var.project_name}-lb-sg"
  description = "Load balancer security group"
}

resource "vkcs_networking_secgroup_rule" "lb_http_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.lb_sg.id
}

# SSH ключ
resource "vkcs_compute_keypair" "main" {
  name       = "${var.project_name}-key"
  public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/my_key.pub")
}