#Тригер для запуска packer-a(Нужно ввести любой символ:)(12323)

# Плагины
packer {
  required_plugins {
    openstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

# Переменные
variable "image_name" {
  type    = string
  default = "web-server-base"
}

variable "flavor" {
  type    = string
  default = "STD2-2-4"
}

variable "source_image" {
  type    = string
  default = "a4e699d3-a66d-45e5-bb5d-70ea7c8de62d"
}

variable "network_id" {
  type    = string
  default = "ec8c610e-6387-447e-83d2-d2c541e88164"
}

# Источник (source) — параметры образа
source "openstack" "ubuntu-nginx" {
  source_image        = var.source_image
  flavor              = var.flavor
  networks = ["e3a04e28-10a7-44a8-9bd5-490e77dd92e2"]
  availability_zone   = "GZ1"
  volume_availability_zone = "GZ1"
  ssh_username        = "ubuntu"
  ssh_timeout         = "3m"
  floating_ip_network = "internet"
  security_groups     = ["test"]
  use_blockstorage_volume = true
  volume_size         = 10
  image_name          = "${var.image_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}

# Сборка
build {
  sources = ["source.openstack.ubuntu-nginx"]

  provisioner "shell" {
    inline = [
      "echo 'Cleaning apt cache...'",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo apt-get clean",
      
      "echo 'Updating system...'",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",

      "echo 'Installing nginx...'",
      "sudo apt-get install -y nginx",
      
      "echo 'Installing PHP...'",
      "sudo apt-get install -y php-fpm php-mysqlnd",
      
      "echo 'Configuring nginx...'",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      
      "echo 'Creating test page...'",
      "echo '<h1>Built with Packer</h1>' | sudo tee /var/www/html/index.html",
      
      "echo 'Cleaning up...'",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}