# Manual Técnico — DevOps Test (Node.js + AWS + EKS + Terraform + CI/CD)

Este documento describe la arquitectura, infraestructura, pipelines y procesos necesarios para construir, testear y desplegar una aplicación Node.js dockerizada en Kubernetes (EKS) utilizando Terraform, Helm y GitHub Actions.

---

## Tabla de Contenidos

- [Manual Técnico — DevOps Test (Node.js + AWS + EKS + Terraform + CI/CD)](#manual-técnico--devops-test-nodejs--aws--eks--terraform--cicd)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Arquitectura General](#arquitectura-general)
    - [Diagrama de alto nivel](#diagrama-de-alto-nivel)
  - [Tecnologías Utilizadas](#tecnologías-utilizadas)
  - [Infraestructura con Terraform](#infraestructura-con-terraform)
    - [Diagrama de Infraestructura](#diagrama-de-infraestructura)
    - [Estructura de terraform](#estructura-de-terraform)
    - [Backend remoto para Terraform](#backend-remoto-para-terraform)
    - [Recursos principales](#recursos-principales)
  - [Estructura de Repositorio](#estructura-de-repositorio)
  - [Despliegue en Kubernetes (Helm)](#despliegue-en-kubernetes-helm)
    - [Diagrama lógico de despliegue con Helm](#diagrama-lógico-de-despliegue-con-helm)
    - [Componentes del Chart](#componentes-del-chart)
  - [CI/CD con Github Actions](#cicd-con-github-actions)
    - [Diagrama CI/CD](#diagrama-cicd)
    - [Workflow CI/CD (resumen lógico)](#workflow-cicd-resumen-lógico)
  - [Build y Distribución del Contenedor](#build-y-distribución-del-contenedor)
    - [Dockerfile](#dockerfile)
    - [Construcción y push](#construcción-y-push)
  - [Acceso Público: LoadBalancer e Ingress](#acceso-público-loadbalancer-e-ingress)
    - [Service Type: Load Balancer](#service-type-load-balancer)
    - [Ingress](#ingress)
  - [Seguridad y Buenas Prácticas](#seguridad-y-buenas-prácticas)
    - [IAM](#iam)
    - [Secrets vs ConfigMaps](#secrets-vs-configmaps)
    - [Escaneo de vulnerabilidades](#escaneo-de-vulnerabilidades)
    - [Pasos para Ejecutar End-to-End](#pasos-para-ejecutar-end-to-end)
  - [Mejoras y Consideraciones para Producción](#mejoras-y-consideraciones-para-producción)
  - [Evidencias](#evidencias)
    - [Terraform](#terraform)

---

## Arquitectura General

### Diagrama de alto nivel

![Diagrama de Infraestructura](docs/images/Arquitectura%20General.png)
## Tecnologías Utilizadas

| Componente                  | Tecnología                                        |
| --------------------------- | ------------------------------------------------- |
| Lenguaje Backend            | Node.js (Express + SQLite)                        |
| Contenedores                | Docker + Buildx (multi-arch)                      |
| Orquestación                | Kubernetes (AWS EKS)                              |
| Infraestructura como código | Terraform                                         |
| Registro de Imágenes        | AWS Elastic Container Registry (ECR)              |
| Despliegue K8s              | Helm 3                                            |
| CI/CD                       | GitHub Actions                                    |
| Escaneo de dependencias     | `npm audit`                                       |
| Escaneo de imágenes         | Trivy (aquasecurity/trivy-action)                 |
| Autoescalamiento            | Horizontal Pod Autoscaler (HPA)                   |
| Configuración               | ConfigMaps + Secrets                              |
| Exposición pública          | Service Type LoadBalancer (e Ingress declarativo) |

## Infraestructura con Terraform

### Diagrama de Infraestructura

![Infra Terraform](docs/images/Infra%20Terraform.png)


### Estructura de terraform
```
terraform/
    └── envs/
    |    └──dev/
    |        ├── backend.tf
    |        ├── locals.tf
    |        ├── main.tf
    |        ├── outputs.tf
    |        ├── variables.tf
    |        └── versions.tf 
    └── modules/
        ├── vpc/
        |    ├── main.tf
        |    ├── outputs.tf
        |    └── variables.tf
        ├── eks/
        |    ├── main.tf
        |    ├── outputs.tf
        |    └── variables.tf
        └── ecr/
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```

### Backend remoto para Terraform
```
terraform {
  backend "s3" {
    bucket         = "devsu-test-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
```
### Recursos principales
* **VPC** Con subnets públicas, Internet Gateway y rutas.
* **EKS Cluster** Con Node Group
* **ECR** Para almacenamiento del contenedor
* **IAM Roles & Policies** Para manejo de permisos
* **Outputs** para manejo e integración con CI/CD:
  * eks_cluster_name
  * ecr_repository_url
  * vpc_id

## Estructura de Repositorio

```
app/
    ├─ .github/
    |   └── workflows/
    |       └── ci-cd.yml/
    ├─ docs/
    ├─ infra/
    |   ├── helm/
    |   └── terraform/
    ├─ shared/
    ├─ users/
    ├─ .gitignore
    ├─ dev.sqlite
    ├─ dockerfile
    ├─ index.js
    ├─ index.test.js
    ├─ package-lock.json
    ├─ package.json
    └─ README.md
```
## Despliegue en Kubernetes (Helm)

### Diagrama lógico de despliegue con Helm
![Despliegue Helms](docs/images/Despliegue%20Helm.png)

### Componentes del Chart

1. **Deployment**
   * Imagen: 690687753978.dkr.ecr.us-east-1.amazonaws.com/devsu-project-dev-app:<tag>
   * replicas: 2 (mínimo)
   * Selector por labels
   * containerPort: 8000

2. **Service (LoadBalancer)**
    * Tipo: LoadBalancer
    * Puerto externo: 80
    * TargetPort: containerPort (8000)
    * Crea un Load Balancer público en AWS.

3. **HPA (Horizontal Pod Autoscaler)**
    * minReplicas: 2
    * maxReplicas: N (configurable)
    * Umbral de CPU (por ejemplo 70%).

4. **Secrets**

    * Para variables sensibles:
        - DATABASE_NAME
        - DATABASE_USER
        - DATABASE_PASSWORD

5. **ConfigMap**

    * Para configuración no sensible:
        - NODE_ENV
        - APP_PORT

6. **Ingress**

    * Definido en templates/ingress.yaml
    * Controlado via values.yaml con:
        - ingress.enabled
        - ingress.host

    * Permite, en escenarios reales, exponer la app vía un Ingress Controller (p. ej., ALB Ingress Controller, NGINX).

## CI/CD con Github Actions
### Diagrama CI/CD
![Diagrama CI/CD](/docs/images/Diagrama%20CI:CD%20.png)

### Workflow CI/CD (resumen lógico)
* JOB `ci`
  * `npm ci`
  * `npm test -- --coverage`
  * `eslint`
  * `npm audit --audit-level=high`
  * Publicación de `coverage/` como artefacto
* JOB `build-and-deploy`
  * Login en AWS con `Github Secrets`
  * Login en ECR
  * `docker buildx build --platform linux/amd64 --push`
  * Trivy scan de la imagen
  * Configurar kubeconfig (`aws eks update-kubeconfig`)
  * `helm upgrade --install app infra/helm/app` con:
    * image.repository
    * image.tag = GIT_SHA
    * image.pullPolicy = Always

## Build y Distribución del Contenedor

### Dockerfile
```dockerfile
FROM node:20-alpine AS deps
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --omit=dev || npm install --omit=dev

FROM node:20-alpine AS runner
WORKDIR /usr/src/app
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY . .
EXPOSE 8000
CMD ["node", "index.js"]
```

### Construcción y push
```bash
export REPO="690687753978.dkr.ecr.us-east-1.amazonaws.com/devsu-project-dev-app"

docker buildx build \
  --platform linux/amd64 \
  -t "$REPO:latest" \
  --push \
  .
```

## Acceso Público: LoadBalancer e Ingress

### Service Type: Load Balancer

El Chart expone un service
```yaml
service:
  type: LoadBalancer
  port: 80
```

Esto provoca que AWS cree un Load Balancer externo con un DNS
```bash
kubectl get svc app-api

NAME      TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
app-api   LoadBalancer   172.20.36.137   ac50dad93f48c41df89cdc568e539614-559219699.us-east-1.elb.amazonaws.com   80:32079/TCP   22h
```

Se puede acceder directamente vía:
```text
http://ac50dad93f48c41df89cdc568e539614-559219699.us-east-1.elb.amazonaws.com
```

### Ingress
Aunque la aplicación se consume mediante el LoadBalancer (para simplificar la prueba), el chart incluye un recurso Ingress parametrizable. Ejemplo de configuración típica en values.yaml:

```yaml
ingress:
  enabled: false
  host: "api.example.com"
```

Y en escenarios de producción:

* Configurar un Ingress Controller (NGINX, AWS ALB Controller).
* Asociar un dominio real (api.example.com) en Route53.
* Configurar un certificado TLS en ACM y referenciarlo en el Ingress.

## Seguridad y Buenas Prácticas
### IAM
Las credenciales usadas por Terraform y GitHub Actions tienen permisos de administrador (para simplificar la prueab). En ambientes productivos es recomendable utilizar sólo los permisos necesarios a los recursos, por ejemplo:
* `eks:DescribeCluster`
* `ecr:*` sobre el repositorio correspondiente.
* `ec2:Describe*`, `ec2:CreateVpc`, etc. (para Terraform).
* `iam:CreateRole`, `iam:AttachRolePolicy` (para roles de EKS).
  
### Secrets vs ConfigMaps
* **Secrets**
  * Datos sensibles: credenciales DB, tokens.
  * Encriptados en etcd (a nivel de cluster, según configuración).
* **ConfigMaps**
  * Configuración no sensible: puertos, flags, entornos.
  * Facilitan cambiar config sin reconstruir la imagen.

### Escaneo de vulnerabilidades
* **npm audit**
  * Analiza dependencias npm (package.json / package-lock.json).
  * Se enfoca en librerías de la aplicación.
* **Trivy**
  * Puede analizar filesystem del repo o la imagen completa.
  * Detecta vulnerabilidades tanto en el sistema operativo base como en bibliotecas de usuario.
### Pasos para Ejecutar End-to-End
1. Infraestructura con terraform
```bash
cd infra/terraform/envs/dev

terraform init
terraform plan
terraform apply -auto-approve

terraform output
```

2. Configurar kubectl con EKS
```bash
aws eks update-kubeconfig \
  --name <eks_cluster_name_output> \
  --region us-east-1

kubectl get nodes
```

3. Build + Push manual de la imagen (si se quiere probar sin CI/CD)
```bash
export REPO=$(terraform -chdir=../infra/terraform output -raw ecr_repository_url)

docker buildx build \
  --platform linux/amd64 \
  -t "$REPO:latest" \
  --push \
  .
```

4. Desplegar con Helm
```bash
cd infra/helm

# Primera vez
helm install app ./app

# Upgrades posteriores
helm upgrade app ./app
```

5. Verificar despliegue
```bash
kubectl get pods
kubectl get svc
kubectl logs deploy/app-api
```

6. Probar la aplicación
```bash
# Obtener EXTERNAL-IP del Service app-api
kubectl get svc app-api

# Probar con curl o navegador
curl http://<EXTERNAL-IP>/
```

## Mejoras y Consideraciones para Producción

* Uso de **entornos múltiples**: `dev`, `staging`, `prod` con workspaces de Terraform y/o múltiples cuentas AWS.
* Uso de **Ingress + TLS**:
    * Dominio en Route53.
    * Certificado TLS en ACM.
    * Ingress Controller (AWS Load Balancer Controller).
* Integración con **monitorización y logging**:
  * CloudWatch, Prometheus, Grafana.
* Uso de **AWS Secrets Manager** o **SSM Parameter Store** para secretos.
* Endurecimiento de seguridad:
    * Policies mínimas en IAM.
    * PodSecurity Standards.
    * etworkPolicies en Kubernetes.
* Configuración de **rollback automático** en caso de despliegues fallidos.

## Evidencias

### Terraform
Se adjuntan capturas de componentes escenciales:

**Creción de vpc**
![tf-vpc](/docs/images/tf-vpc.png)

**Creción de repository**
![tf-ecr](/docs/images/tf-repository.png)

**Creción de cluster**
![tf-cluster](/docs/images/tf-cluster.png)

**Creción de outputs**
![tf-outputs](/docs/images/tf-outputs.png)

