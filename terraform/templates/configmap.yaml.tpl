apiVersion: v1
kind: ConfigMap
metadata:
  name: terraform-outputs
  namespace: web-app
data:
  load_balancer_ip: "${lb_ip}"
