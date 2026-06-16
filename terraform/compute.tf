# Бастион в публичной подсети
resource "vkcs_compute_instance" "bastion" {
  name      = "${var.project_name}-bastion"
  flavor_id = "9cdbca68-5e15-4c54-979d-9952785ba33e"
  image_id  = var.image_name
  key_pair  = vkcs_compute_keypair.main.name

  network {
    uuid = vkcs_networking_network.vpc.id
    fixed_ip_v4 = "192.168.1.50"
  }

  security_group_ids = [vkcs_networking_secgroup.bastion_sg.id]

  block_device {
    uuid                  = var.image_name
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 10
    volume_type           = "ceph-ssd"
    boot_index            = 0
    delete_on_termination = true
  }

  depends_on = [vkcs_networking_router_interface.public]
}

# Floating IP для бастиона
resource "vkcs_networking_floatingip" "bastion" {
  pool = data.vkcs_networking_network.external.name
  depends_on = [vkcs_compute_instance.bastion]
}

# Получаем порт бастиона
data "vkcs_networking_port" "bastion" {
  fixed_ip   = "192.168.1.50"
  network_id = vkcs_networking_network.vpc.id
  depends_on = [vkcs_compute_instance.bastion]
}

# Привязка Floating IP к порту бастиона
resource "vkcs_networking_floatingip_associate" "bastion" {
  floating_ip = vkcs_networking_floatingip.bastion.address
  port_id     = data.vkcs_networking_port.bastion.id
}

# Веб-серверы в приватной подсети
resource "vkcs_compute_instance" "web" {
  count = var.web_count

  name      = "${var.project_name}-web-${count.index + 1}"
  flavor_id = "9cdbca68-5e15-4c54-979d-9952785ba33e"
  image_id  = var.image_name
  key_pair  = vkcs_compute_keypair.main.name

  network {
    uuid = vkcs_networking_network.vpc.id
    fixed_ip_v4 = "192.168.2.${100 + count.index}"
  }

  security_group_ids = [vkcs_networking_secgroup.web_sg.id]

  block_device {
    uuid                  = var.image_name
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 10
    volume_type           = "ceph-ssd"
    boot_index            = 0
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    systemctl start nginx
    echo "<h1>Web Server ${count.index + 1} - Built with Packer</h1>" > /var/www/html/index.html
  EOF

  depends_on = [vkcs_networking_router_interface.private, vkcs_compute_instance.bastion]
}