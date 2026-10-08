# PetStore Application - Cloud-Native DevOps & GitOps

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326ce5.svg?logo=kubernetes)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-v3-0f1689.svg?logo=helm)](https://helm.sh/)
[![Trivy](https://img.shields.io/badge/Trivy-Secured-brightgreen.svg?logo=aquasec)](https://aquasecurity.github.io/trivy/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-orange.svg?logo=argo)](https://argo-cd.readthedocs.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-red.svg?logo=jenkins)](https://www.jenkins.io/)

A production-ready, cloud-native DevOps deployment of the **Petstore Application** (MyBatis JPetStore Java EE web application) featuring automated CI/CD pipelines, containerization, vulnerability scanning, Helm chart packaging, visual Helm release management, and GitOps continuous delivery.

> 📖 **Complete DevOps Guide**: Detailed architectural explanations, manifests walkthrough, and troubleshooting commands are available in [DEVOPS_GUIDE.md](DEVOPS_GUIDE.md).

---

## 🚀 Quick Start Guide

### 1. Run with Docker
```bash
# Build and run locally via helper script
./scripts/build-and-run.sh

# Or directly with Docker:
docker build -t petstore-app:latest .
docker run -d -p 8080:8080 --name petstore-app petstore-app:latest
```
Access the application at: `http://localhost:8080/jpetstore/` or `http://localhost:8080/`

---

### 2. Run with Docker Compose
```bash
docker compose up --build -d
docker compose ps
docker compose logs -f
```

---

### 3. Run Trivy Vulnerability Scan
```bash
# Scan filesystem, IaC configurations, and Docker image
./scripts/trivy-scan.sh petstore-app:latest
```
Reports are automatically saved in `security-reports/`.

---

### 4. Deploy to Kubernetes (k8s Manifests)
```bash
./scripts/k8s-deploy.sh

# Or with Kustomize:
kubectl apply -k k8s/
```

---

### 5. Deploy with Helm Chart
```bash
./scripts/helm-deploy.sh petstore petstore latest

# Or manually:
helm upgrade --install petstore helm/petstore \
  --namespace petstore \
  --create-namespace
```

---

### 6. Visual Release Management (Komodor Helm Dashboard)
```bash
./scripts/helm-dashboard.sh
```
Open `http://localhost:8080` to manage releases, inspect values, and visualize Kubernetes resources.

---

### 7. GitOps Continuous Delivery with ArgoCD
```bash
# Install ArgoCD & deploy Petstore GitOps app
./argocd/install-argocd.sh
```
Port forward ArgoCD dashboard:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Access at `https://localhost:8080` (Username: `admin`).

---

## 📁 Repository Structure

```
Petstore_App/
|-- Dockerfile                     # Multi-stage production container build (non-root UID 1001)
|-- docker-compose.yaml            # Local multi-service orchestrator with healthchecks
|-- Jenkinsfile                    # Multi-stage CI/CD Declarative Pipeline
|-- trivy.yaml                     # Trivy vulnerability scanner configuration
|-- DEVOPS_GUIDE.md                # Comprehensive Hindi & English DevOps guide
|-- pom.xml                        # Maven project descriptor
|-- k8s/                           # Kubernetes YAML manifests
|   |-- namespace.yaml             # petstore namespace
|   |-- configmap.yaml             # App & JVM configurations
|   |-- secret.yaml                # App secrets
|   |-- deployment.yaml            # Deployment with anti-affinity, probes & resources
|   |-- service.yaml               # ClusterIP & NodePort services
|   |-- ingress.yaml               # NGINX Ingress rules
|   |-- hpa.yaml                   # Horizontal Pod Autoscaler (2-5 replicas)
|   `-- kustomization.yaml         # Kustomize manifest
|-- helm/
|   `-- petstore/                  # Production-grade Helm 3 Chart
|       |-- Chart.yaml
|       |-- values.yaml
|       `-- templates/
|-- helm-dashboard/                # Komodor Helm Dashboard setup
|   |-- README.md
|   `-- k8s/                       # In-cluster RBAC & deployment manifests
|-- argocd/                        # ArgoCD GitOps configuration
|   |-- README.md
|   |-- application.yaml           # ArgoCD Application CRD (Helm based)
|   |-- application-k8s.yaml       # ArgoCD Application CRD (Manifest based)
|   `-- install-argocd.sh          # One-click ArgoCD installer script
`-- scripts/                       # DevOps automation shell scripts
    |-- build-and-run.sh
    |-- trivy-scan.sh
    |-- k8s-deploy.sh
    |-- helm-deploy.sh
    `-- helm-dashboard.sh
```

---

## 🔒 Security Best Practices Implemented
- **Least Privilege Execution**: Container processes run as non-root user `tomcat` (UID `1001`).
- **Minimal Attack Surface**: Default Tomcat sample apps and managers removed.
- **Vulnerability Governance**: Automated Trivy scans in Jenkins CI before image push.
- **GitOps Drift Detection**: ArgoCD automatically re-syncs state if manual changes occur.
- **High Availability**: Pod Anti-Affinity and HPA (CPU/Memory utilization thresholds).
