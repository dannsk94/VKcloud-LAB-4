# Лабораторная работа №4: CI/CD и GitOps

## 📋 Описание

Настройка CI/CD пайплайна для автоматического развертывания инфраструктуры (Terraform + Packer) и приложения (Kubernetes + ArgoCD) с использованием GitOps подхода.

## 🔄 Порядок работы

1. **Packer** — создание образа ВМ с nginx + PHP (ручной запуск)
2. **Terraform** — развертывание инфраструктуры (validate → plan → apply)
3. **Kubernetes** — кластер для контейнеризованных приложений
4. **ArgoCD** — GitOps синхронизация с репозиторием
5. **Destroy** — удаление инфраструктуры (ручной запуск)

## 📁 Структура проекта

```text
VKcloud-LAB-4/
├── .github/workflows/
│ ├── lab4_github-ci.yml # Terraform CI/CD
│ └── lab4_packer.yml # Packer Build (ручной)
├── terraform/
│ ├── main.tf # Провайдеры и S3 backend
│ ├── variables.tf # Переменные
│ ├── outputs.tf # Выходные данные
│ ├── network.tf # Сеть, подсети, SG, SSH ключ
│ ├── compute.tf # Бастион и веб-серверы
│ ├── database.tf # PostgreSQL
│ ├── loadbalancer.tf # Балансировщик
│ └── templates/
│ └── configmap.yaml.tpl # Шаблон ConfigMap
├── kubernetes/
│ ├── namespace.yaml # Namespace web-app
│ ├── deployment.yaml # Nginx (2 реплики)
│ ├── service.yaml # LoadBalancer
│ ├── ingress.yaml # Ingress
│ ├── configmap.yaml # ConfigMap с IP LB
│ └── kustomization.yaml # Kustomize
├── argocd/
│ └── application.yaml # ArgoCD Application
├── packer/
│ └── lab-packer-config.pkr.hcl # Packer образ
└── README.md
```


## 🏗️ Архитектура

| Компонент | Технология | Описание |
|-----------|------------|----------|
| **CI/CD** | GitHub Actions | Автоматизация сборки и деплоя |
| **Образы** | Packer | Ubuntu 22.04 + nginx + PHP |
| **Инфраструктура** | Terraform | VPC, ВМ, БД, балансировщик |
| **Оркестрация** | Kubernetes | Кластер (1 мастер, 1 воркер) |
| **GitOps** | ArgoCD | Автосинхронизация с Git |

## 🚀 CI/CD Пайплайн

### Terraform CI/CD (`lab4_github-ci.yml`)

| Job | Триггер | Действие |
|-----|---------|----------|
| `validate` | push, PR | `terraform validate` |
| `plan` | push, PR | `terraform plan` |
| `apply` | push в main | `terraform apply` (подтверждение) |
| `destroy` | workflow_dispatch | `terraform destroy` |

### Packer Build (`lab4_packer.yml`)

| Job | Триггер | Действие |
|-----|---------|----------|
| `packer_build` | workflow_dispatch | Сборка образа → push ID |

## 🔗 Интеграция Terraform и Kubernetes

Terraform генерирует ConfigMap с IP балансировщика → пушится в Git → ArgoCD синхронизирует → ConfigMap появляется в Kubernetes.

## 🛠️ Использование

### Packer (ручной запуск)
Actions → Packer Build → Run workflow

### Terraform (автоматически)
```bash
git push origin main
```

**Доступ к ArgoCD**

```bash
ssh -L 6443:192.168.1.193:6443 ubuntu@IP_БАСТИОНА
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
```

## Удаление

Actions → Terraform CI/CD → Run workflow (запустит Destroy)

## 📝 Секреты GitHub

| Secret | Назначение |
|--------|------------|
| `CLOUDS_YAML` | Аутентификация VK Cloud |
| `AWS_ACCESS_KEY_ID` | Доступ к S3 |
| `AWS_SECRET_ACCESS_KEY` | Доступ к S3 |
| `SSH_PUBLIC_KEY` | Публичный SSH ключ |
| `PACKER_GITHUB_API_TOKEN` | GitHub токен |

## 📤 Выходные данные Terraform

| Параметр | Описание |
|----------|----------|
| `bastion_public_ip` | Внешний IP бастиона |
| `load_balancer_public_ip` | Внешний IP балансировщика |
| `web_servers_private_ips` | Приватные IP веб-серверов |
| `db_host` | Приватный IP БД |