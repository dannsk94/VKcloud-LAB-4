# Генерация случайного пароля
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()[]{}<>:?"
}

# Сохранение пароля в файл
resource "local_file" "db_password" {
  content  = "Host: ${vkcs_db_instance.main.ip[0]}\nDatabase: ${vkcs_db_database.app.name}\nUser: ${vkcs_db_user.app.name}\nPassword: ${random_password.db_password.result}"
  filename = "${path.module}/db_password.txt"
}

# Управляемый PostgreSQL в приватной подсети
resource "vkcs_db_instance" "main" {
  name              = "${var.project_name}-db"
  availability_zone = "GZ1"
  flavor_id         = "2df6e3ec-5939-4d28-a818-89558ff1b7ab"
  volume_type       = "ceph-ssd"
  size              = 10

  network {
    uuid = vkcs_networking_network.vpc.id
    fixed_ip_v4 = "192.168.2.200"
  }

  datastore {
    type    = "postgresql"
    version = "15"
  }

  backup_schedule {
    name           = "backup_daily"
    interval_hours = 24
    keep_count     = 7
    start_hours    = 0
    start_minutes  = 0
  }

  depends_on = [vkcs_networking_router_interface.private]
}

resource "vkcs_db_database" "app" {
  name    = var.db_name
  dbms_id = vkcs_db_instance.main.id
}

resource "vkcs_db_user" "app" {
  name      = var.db_user
  password  = random_password.db_password.result
  dbms_id   = vkcs_db_instance.main.id
  databases = [vkcs_db_database.app.name]
}