# Балансировщик в публичной подсети
resource "vkcs_lb_loadbalancer" "main" {
  name          = "${var.project_name}-lb"
  vip_subnet_id = vkcs_networking_subnet.public.id

  depends_on = [vkcs_networking_router_interface.public]
}

resource "vkcs_lb_listener" "http" {
  name            = "${var.project_name}-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = vkcs_lb_loadbalancer.main.id
}

resource "vkcs_lb_pool" "web" {
  name        = "${var.project_name}-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = vkcs_lb_listener.http.id
}

resource "vkcs_lb_monitor" "web" {
  name        = "${var.project_name}-monitor"
  type        = "HTTP"
  delay       = 10
  timeout     = 5
  max_retries = 3
  url_path    = "/"
  pool_id     = vkcs_lb_pool.web.id
}

resource "vkcs_lb_member" "web" {
  count = var.web_count

  name          = "${var.project_name}-member-${count.index + 1}"
  address       = vkcs_compute_instance.web[count.index].access_ip_v4
  protocol_port = 80
  pool_id       = vkcs_lb_pool.web.id
  subnet_id     = vkcs_networking_subnet.private.id
}

# Floating IP для балансировщика
resource "vkcs_networking_floatingip" "lb" {
  pool = data.vkcs_networking_network.external.name
}

resource "vkcs_networking_floatingip_associate" "lb" {
  floating_ip = vkcs_networking_floatingip.lb.address
  port_id     = vkcs_lb_loadbalancer.main.vip_port_id
}