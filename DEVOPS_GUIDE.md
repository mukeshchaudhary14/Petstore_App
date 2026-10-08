# PetStore Application - Complete End-to-End DevOps & GitOps Guide

Ye guide **Petstore_App** ke complete DevOps lifecycle ko cover karti hai — bilkul **MedVault** project ki tarah. Isme Docker containerization, Docker Compose local setup, Trivy security scanning, Jenkins CI/CD pipeline, Kubernetes deployment, Helm chart packaging, Komodor Helm Dashboard visualization, aur ArgoCD GitOps continuous deployment shamil hain.

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Project Fixes & Prerequisites](#2-project-fixes--prerequisites)
3. [Docker & Containerization](#3-docker--containerization)
4. [Docker Compose Local Environment](#4-docker-compose-local-environment)
5. [Trivy Vulnerability & Security Scanning](#5-trivy-vulnerability--security-scanning)
6. [Jenkins CI/CD Declarative Pipeline](#6-jenkins-cicd-declarative-pipeline)
7. [Kubernetes Manifests (k8s/)](#7-kubernetes-manifests-k8s)
8. [Helm Packaging & Chart (helm/petstore/)](#8-helm-packaging--chart-helmpetstore)
9. [Komodor Helm Dashboard](#9-komodor-helm-dashboard)
10. [ArgoCD GitOps Deployment](#10-argocd-gitops-deployment)
11. [Troubleshooting & Verification Commands](#11-troubleshooting--verification-commands)

---

## 1. Architecture Overview

```
+---------------------------------------------------------------------------------------------------------+
|                                    DEV / SOURCE CODE REPOSITORY                                         |
|                               (GitHub: mukeshchaudhary14/Petstore_App)                                   |
+---------------------------------------------------------------------------------------------------------+
                                                     |
                                                     v (Push / Webhook)
+---------------------------------------------------------------------------------------------------------+
|                                        JENKINS CI/CD PIPELINE                                           |
|  1. Checkout -> 2. Maven Build/Test -> 3. Trivy FS Scan -> 4. Docker Build                             |
|  5. Trivy Image Scan -> 6. Push to DockerHub -> 7. Helm Lint -> 8. Trigger Deploy                       |
+---------------------------------------------------------------------------------------------------------+
                                                     |
                                                     v
+---------------------------------------------------------------------------------------------------------+
|                                        DOCKER HUB REGISTRY                                              |
|                               mukeshchaudhary14/petstore-app:latest                                     |
+---------------------------------------------------------------------------------------------------------+
                                                     |
                                                     v
+---------------------------------------------------------------------------------------------------------+
|                                        GITOPS CONTROLLER (ARGOCD)                                       |
|                  Tracks Git Repository (helm/petstore) & Reconciles Cluster State                       |
+---------------------------------------------------------------------------------------------------------+
                                                     |
                                                     v
+---------------------------------------------------------------------------------------------------------+
|                                          KUBERNETES CLUSTER                                             |
|  - Namespace: petstore                                                                                  |
|  - Ingress Controller (NGINX) -> Service (ClusterIP:80)                                                 |
|  - Deployment (2-5 Pods Autoscaled via HPA)                                                             |
|  - Hardened Non-Root SecurityContext (UID 1001)                                                         |
|  - Liveness & Readiness Probes                                                                          |
|  - ConfigMap & Secret Mounts                                                                            |
+---------------------------------------------------------------------------------------------------------+
                                                     ^
                                                     |
+---------------------------------------------------------------------------------------------------------+
|                                       KOMODOR HELM DASHBOARD                                            |
|                               Visualizes Helm releases, values, diffs & logs                            |
+---------------------------------------------------------------------------------------------------------+
```

---

## 2. Project Fixes & Prerequisites

Iss project me original repo me kuch missing files aur errors the jinko resolve kiya gaya:
1. **Missing `pom.xml`**: Repository me Maven `pom.xml` file missing thi, jisko compatible MyBatis JPetStore Maven configuration ke sath add kiya gaya.
2. **Missing MyBatis XML Mappers**: `ItemMapper.xml`, `LineItemMapper.xml`, `OrderMapper.xml`, `ProductMapper.xml`, aur `SequenceMapper.xml` upstream repo se download karke add ki gayi.
3. **Directory Path Space Bug**: `src/main/resources/org/mybatis/jpetstore /` folder name me trailing space tha jisse Spring XML load nahi kar pata tha; use rename kiya gaya.
4. **Duplicate Classes**: `org.mybatis.jpetstore.actions` aur `org.mybatis.jpetstore.web.actions` dono jagah duplicate files thi jisse compiler clash hota tha; invalid duplicate folder remove kiya gaya.

---

## 3. Docker & Containerization

### Multi-Stage Dockerfile Highlights:
- **Build Stage**: `maven:3.9-eclipse-temurin-17-alpine` ka use karke clean WAR artifact compile karta hai.
- **Runtime Stage**: `tomcat:9.0-jre17-temurin-jammy` hardened image. Default sample webapps delete kiye gaye hain.
- **Security Compliance**: Non-root user `tomcat` (UID `1001`) create kiya gaya hai taaki container root privileges se run na ho (Trivy compliance).
- **Dual Deployment**: `jpetstore.war` ko `ROOT.war` aur `jpetstore.war` dono me deploy kiya gaya hai taaki root URL `/` aur context path `/jpetstore/` dono kaam karein.
- **Health Checks**: Built-in container health check probe.

### Docker Commands:
```bash
# 1. Build Docker image
docker build -t petstore-app:latest .

# 2. Run container
docker run -d -p 8080:8080 --name petstore-app petstore-app:latest

# 3. Check logs & status
docker ps
docker logs -f petstore-app

# 4. Access application
curl -I http://localhost:8080/jpetstore/
```

Or simply run the automated script:
```bash
./scripts/build-and-run.sh
```

---

## 4. Docker Compose Local Environment

`docker-compose.yaml` local machine par single-command testing aur development ke liye configured hai:
- Container Name: `petstore-app`
- Port Mapping: `8080:8080`
- Resource Limits: 1 CPU, 1024MB Memory limit
- Logging Driver: `json-file` with log rotation (10m max-size)
- Health Check: Automatically checks `http://localhost:8080/jpetstore/`
- Isolated Network: `petstore-network` bridge

### Docker Compose Commands:
```bash
# Start the application in background with fresh build
docker compose up --build -d

# Check service status & health
docker compose ps

# View real-time logs
docker compose logs -f

# Stop and clean up
docker compose down
```

---

## 5. Trivy Vulnerability & Security Scanning

Security DevSecOps best practices ke according `trivy.yaml` aur `scripts/trivy-scan.sh` add kiya gaya hai:

### What gets scanned:
1. **Filesystem Scan (`trivy fs`)**: Source code, dependencies aur leaked secrets/API keys scan karta hai.
2. **Docker Image Scan (`trivy image`)**: Container OS packages aur libraries me `HIGH` aur `CRITICAL` CVEs detect karta hai.
3. **IaC Misconfiguration Scan (`trivy config`)**: Kubernetes YAML aur Helm charts me security misconfigurations scan karta hai.

### Running Trivy Scan:
```bash
# Run complete scan suite
./scripts/trivy-scan.sh petstore-app:latest
```
Scan ke baad reports `security-reports/` folder me save hoti hain:
- `trivy-fs-report.txt` & `trivy-fs-report.json`
- `trivy-image-report.txt` & `trivy-image-report.json`
- `trivy-iac-report.txt`

---

## 6. Jenkins CI/CD Declarative Pipeline

`Jenkinsfile` me industry-standard CI/CD stages configure ki gayi hain:

### Pipeline Stages:
1. **Checkout Code**: Git repository checkout karta hai.
2. **Build & Test Application**: Maven package compile karta hai aur JUnit reports generate karta hai.
3. **Trivy FS Scan**: Code & libraries par security scanning perform karta hai.
4. **Docker Build**: Application container image create karta hai with unique build number tag (`mukeshchaudhary14/petstore-app:${BUILD_NUMBER}`).
5. **Trivy Image Scan**: Container image release hone se pehle CVE vulnerability check karta hai.
6. **Docker Push to Registry**: Image ko Docker Hub registry me push karta hai using Jenkins Credentials.
7. **Helm Lint & IaC Scan**: Helm chart syntax aur configuration validate karta hai.
8. **Deploy to Kubernetes**: Selected deployment method (`Helm`, `ArgoCD-GitOps`, ya `Kubectl`) se auto-deploy karta hai.

### Required Jenkins Credentials:
- **`dockerhub-credentials`**: Username/Password credential Docker Hub login ke liye.
- **`kubeconfig`**: Secret file credential Kubernetes cluster access ke liye (agar Jenkins direct k8s deploy kare).

---

## 7. Kubernetes Manifests (`k8s/`)

Production-ready declarative YAML manifests `k8s/` directory me present hain:

| Manifest | Purpose |
| :--- | :--- |
| `namespace.yaml` | Dedicated `petstore` namespace create karta hai |
| `configmap.yaml` | Application configuration aur JVM tuning parameters |
| `secret.yaml` | Sensitive environment variables |
| `deployment.yaml` | 2 replicas, non-root security context (UID 1001), Pod anti-affinity, liveness/readiness probes, resource limits |
| `service.yaml` | ClusterIP (port 80 -> 8080) aur NodePort (port 30080) service |
| `ingress.yaml` | NGINX Ingress Controller rules for `petstore.local` |
| `hpa.yaml` | HorizontalPodAutoscaler (scales 2 to 5 pods at 75% CPU / 80% RAM) |
| `kustomization.yaml` | Kustomize manifest for single-command deploy (`kubectl apply -k k8s/`) |

### Deploy via kubectl:
```bash
# Single command deploy
./scripts/k8s-deploy.sh

# Or manual apply:
kubectl apply -k k8s/

# Verify:
kubectl get pods,svc,ingress,hpa -n petstore
```

---

## 8. Helm Packaging & Chart (`helm/petstore/`)

Application ko standard Helm chart me package kiya gaya hai taaki parameterization aur multi-environment deployment (dev/staging/prod) easy ho:

```
helm/petstore/
|-- Chart.yaml
|-- values.yaml
`-- templates/
    |-- _helpers.tpl
    |-- configmap.yaml
    |-- deployment.yaml
    |-- hpa.yaml
    |-- ingress.yaml
    |-- NOTES.txt
    |-- secret.yaml
    |-- service.yaml
    `-- serviceaccount.yaml
```

### Helm Commands:
```bash
# 1. Lint the chart
helm lint helm/petstore

# 2. Dry run template rendering
helm template petstore helm/petstore --namespace petstore

# 3. Install or Upgrade release
helm upgrade --install petstore helm/petstore \
  --namespace petstore \
  --create-namespace \
  --set image.tag="latest"

# 4. View release status
helm status petstore -n petstore

# 5. Rollback release if needed
helm rollback petstore 1 -n petstore
```

Or run the script:
```bash
./scripts/helm-deploy.sh petstore petstore latest
```

---

## 9. Komodor Helm Dashboard

Komodor Helm Dashboard ek interactive visual web UI provide karta hai jisse cluster ke saare Helm charts aur releases manage kiye ja sakte hain.

### How to Run Helm Dashboard:

#### Method A: Using Helm Plugin (Local)
```bash
helm plugin install https://github.com/komodorio/helm-dashboard
helm dashboard --port 8080 --bind 0.0.0.0
```

#### Method B: Using Docker
```bash
docker run --rm -it \
  --name helm-dashboard \
  -p 8080:8080 \
  -v ~/.kube/config:/root/.kube/config:ro \
  ghcr.io/komodorio/helm-dashboard:latest \
  --bind=0.0.0.0 --port=8080
```

#### Method C: Deploy Inside Kubernetes Cluster
```bash
# Apply RBAC and deployment
kubectl apply -f helm-dashboard/k8s/rbac.yaml
kubectl apply -f helm-dashboard/k8s/deployment.yaml

# Port forward to local browser
kubectl port-forward svc/helm-dashboard-service -n helm-dashboard 8080:8080
```

Open browser at: `http://localhost:8080`

Or simply run:
```bash
./scripts/helm-dashboard.sh
```

---

## 10. ArgoCD GitOps Deployment

ArgoCD continuous delivery controller ke sath GitOps automation setup:

### How it works:
1. Git repo me `helm/petstore/values.yaml` me new image tag push hota hai.
2. ArgoCD repository ko monitor karta hai aur diff detect karta hai.
3. Automated sync policy ke through ArgoCD zero-downtime rolling update execute karta hai.
4. Agar koi manually `kubectl` se cluster me resource change karta hai, toh `selfHeal: true` automatically use Git ke version par revert kar deta hai.

### Installation & Application Setup:
```bash
# 1. Automated installation
./argocd/install-argocd.sh

# 2. Manual Apply:
kubectl apply -f argocd/application.yaml

# 3. Access ArgoCD UI:
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

---

## 11. Troubleshooting & Verification Commands

### Check Kubernetes Pod Logs:
```bash
kubectl logs -f -l app=petstore -n petstore
```

### Port Forward Application:
```bash
kubectl port-forward svc/petstore-service 8080:80 -n petstore
```

### Access URLs:
- **Application Web UI**: `http://localhost:8080/jpetstore/`
- **Application Root URL**: `http://localhost:8080/`
- **Helm Dashboard**: `http://localhost:8080`
- **ArgoCD Dashboard**: `https://localhost:8080`

---
*Developed & Maintained by Mukesh Chaudhary for Petstore_App DevOps & GitOps Automation.*
