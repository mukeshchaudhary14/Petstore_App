# PetStore Application - Complete End-to-End DevOps & GitOps Guide

This guide covers the complete DevOps and GitOps lifecycle for the **Petstore_App** — structured and implemented just like the **MedVault** enterprise project. It includes Docker multi-stage containerization, Docker Compose local setup, Trivy security vulnerability scanning, Jenkins CI/CD declarative pipeline, Kubernetes manifests, Helm 3 chart packaging, Komodor Helm Dashboard visualization, and ArgoCD continuous GitOps delivery.

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Project Fixes & Prerequisites](#2-project-fixes--prerequisites)
3. [Docker & Multi-Stage Containerization](#3-docker--multi-stage-containerization)
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

In the original repository, several missing files and compilation bugs were identified and resolved:
1. **Missing `pom.xml`**: The repository lacked a Maven `pom.xml`. A fully compatible Maven descriptor configured for Java 17/21 runtime compatibility was added.
2. **Missing MyBatis XML Mappers**: Upstream XML mapping files (`ItemMapper.xml`, `LineItemMapper.xml`, `OrderMapper.xml`, `ProductMapper.xml`, and `SequenceMapper.xml`) were retrieved and configured under `src/main/resources/org/mybatis/jpetstore/mapper/`.
3. **Directory Path Space Bug**: The folder `src/main/resources/org/mybatis/jpetstore /` contained a trailing space that prevented Spring from locating XML mappers at runtime; it was renamed to `jpetstore`.
4. **Duplicate Classes**: Duplicate action classes under `org.mybatis.jpetstore.actions` and `org.mybatis.jpetstore.web.actions` were causing package conflicts; the invalid directory was pruned.
5. **WAR Packaging Compatibility**: Updated `maven-war-plugin` to version `3.4.0` and skipped outdated `animal-sniffer` Java 1.6 checks to allow clean compilation on modern JDKs.

---

## 3. Docker & Multi-Stage Containerization

### Multi-Stage Dockerfile Highlights:
- **Build Stage**: Uses `maven:3.9-eclipse-temurin-17-alpine` to compile and package the clean WAR artifact (`target/jpetstore.war`).
- **Runtime Stage**: Uses hardened `tomcat:9.0-jre17-temurin-jammy`. All default sample webapps (`docs`, `examples`, `manager`, `ROOT`) are purged.
- **Security Compliance**: Creates and runs under a dedicated non-root user `tomcat` (UID `1001`) to comply with DevSecOps standards and Trivy scans.
- **Dual Deployment**: `jpetstore.war` is copied to both `ROOT.war` and `jpetstore.war` inside Tomcat webapps, making the application accessible via both root `/` and `/jpetstore/`.
- **Health Checks**: Built-in container healthcheck probe checks application status automatically.

### Docker Commands:
```bash
# 1. Build Docker image
docker build -t petstore-app:latest .

# 2. Run container (mapped to host port 8082 to avoid Jenkins port 8080 collision)
docker run -d -p 8082:8080 --name petstore-app petstore-app:latest

# 3. Check logs & status
docker ps
docker logs -f petstore-app

# 4. Access application
curl -I http://localhost:8082/jpetstore/
```

Or execute the automated helper script:
```bash
./scripts/build-and-run.sh
```

---

## 4. Docker Compose Local Environment

`docker-compose.yaml` provides single-command orchestration for local testing and development:
- **Container Name**: `petstore-app`
- **Port Mapping**: `8082:8080` (avoids conflict with Jenkins on port 8080)
- **Resource Limits**: 1.0 CPU, 1024MB Memory limit
- **Logging Driver**: `json-file` with automatic log rotation (max 10MB, 3 files)
- **Health Check**: Automatically monitors `http://localhost:8080/jpetstore/`
- **Isolated Network**: `petstore-network` bridge

### Docker Compose Commands:
```bash
# Start application in background with fresh build
docker compose up --build -d

# Check service status & health
docker compose ps

# View live container logs
docker compose logs -f

# Stop and clean up containers
docker compose down
```

---

## 5. Trivy Vulnerability & Security Scanning

In accordance with DevSecOps best practices, `trivy.yaml` and `scripts/trivy-scan.sh` provide automated security validation:

### Scan Targets:
1. **Filesystem Scan (`trivy fs`)**: Scans source code, dependencies, and leaked secrets/API tokens.
2. **Docker Image Scan (`trivy image`)**: Scans container OS packages and application libraries for `HIGH` and `CRITICAL` CVEs.
3. **IaC Misconfiguration Scan (`trivy config`)**: Scans Kubernetes manifests and Helm charts for security misconfigurations.

### Running Trivy Scan:
```bash
# Run complete security scan suite
./scripts/trivy-scan.sh petstore-app:latest
```

Scan reports are saved to the `security-reports/` directory:
- `trivy-fs-report.txt` & `trivy-fs-report.json`
- `trivy-image-report.txt` & `trivy-image-report.json`
- `trivy-iac-report.txt`

---

## 6. Jenkins CI/CD Declarative Pipeline

The declarative `Jenkinsfile` defines an enterprise-grade CI/CD pipeline with 8 automated stages:

### Pipeline Stages:
1. **Checkout Code**: Checks out source code from Git repository.
2. **Build & Test Application**: Compiles application with Maven and generates JUnit test reports.
3. **Trivy FS Scan**: Scans repository code and dependencies for security flaws.
4. **Docker Build**: Builds container image tagged with the unique build number (`mukeshchaudhary14/petstore-app:${BUILD_NUMBER}`).
5. **Trivy Image Scan**: Scans the newly created container image before releasing.
6. **Docker Push to Registry**: Authenticates and pushes image to Docker Hub using Jenkins credentials.
7. **Helm Lint & IaC Scan**: Validates Helm chart syntax and infrastructure-as-code security.
8. **Deploy to Kubernetes**: Deploys via selected method (`Helm`, `ArgoCD-GitOps`, or `Kubectl`).

### Required Jenkins Credentials:
- **`dockerhub-credentials`**: Username/Password credential for Docker Hub registry authentication.
- **`kubeconfig`**: Secret file credential for Kubernetes cluster access (if direct cluster deployment is enabled in Jenkins).

---

## 7. Kubernetes Manifests (`k8s/`)

Declarative production-ready YAML manifests are located in the `k8s/` directory:

| Manifest | Purpose |
| :--- | :--- |
| `namespace.yaml` | Creates dedicated `petstore` namespace |
| `configmap.yaml` | Stores application configurations and JVM tuning options |
| `secret.yaml` | Stores sensitive environment variables and tokens |
| `deployment.yaml` | 2 Replicas, non-root security context (UID 1001), Pod anti-affinity, liveness/readiness probes, resource limits |
| `service.yaml` | ClusterIP (port 80 -> 8080) and NodePort (port 30080) services |
| `ingress.yaml` | NGINX Ingress Controller rules for `petstore.local` |
| `hpa.yaml` | HorizontalPodAutoscaler (scales 2 to 5 pods at 75% CPU / 80% Memory) |
| `kustomization.yaml` | Kustomize manifest for single-command deployment (`kubectl apply -k k8s/`) |

### Deploy via kubectl:
```bash
# Automated deployment script
./scripts/k8s-deploy.sh

# Or manual apply with Kustomize:
kubectl apply -k k8s/

# Verify status:
kubectl get pods,svc,ingress,hpa -n petstore
```

---

## 8. Helm Packaging & Chart (`helm/petstore/`)

The application is packaged into a standard Helm 3 chart for parameterized, multi-environment deployments (dev, staging, prod):

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
# 1. Lint the Helm chart
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

Or execute the helper script:
```bash
./scripts/helm-deploy.sh petstore petstore latest
```

---

## 9. Komodor Helm Dashboard

Komodor Helm Dashboard provides an interactive visual web interface to monitor, inspect, and manage all Helm charts and releases across your cluster.

### How to Run Helm Dashboard:

#### Method A: Using Helm CLI Plugin (Local)
```bash
# Install plugin (if not already installed)
helm plugin install https://github.com/komodorio/helm-dashboard

# Launch on port 8085
./scripts/helm-dashboard.sh
# Or manually:
helm dashboard --port 8085 --bind 0.0.0.0
```

#### Method B: Using Docker
```bash
docker run --rm -it \
  --name helm-dashboard \
  -p 8085:8080 \
  -v ~/.kube/config:/root/.kube/config:ro \
  ghcr.io/komodorio/helm-dashboard:latest \
  --bind=0.0.0.0 --port=8080
```

#### Method C: Deploy Inside Kubernetes Cluster
```bash
# Apply RBAC and Deployment
kubectl apply -f helm-dashboard/k8s/rbac.yaml
kubectl apply -f helm-dashboard/k8s/deployment.yaml

# Port-forward to local browser
kubectl port-forward svc/helm-dashboard-service -n helm-dashboard 8085:8080
```

Open your browser at: **`http://localhost:8085`**

---

## 10. ArgoCD GitOps Deployment

ArgoCD continuously reconciles the desired state defined in this Git repository with the actual state in the Kubernetes cluster:

### GitOps Workflow:
1. When a new image tag or value is pushed to `helm/petstore/values.yaml` in Git, ArgoCD detects the change.
2. ArgoCD automatically executes a zero-downtime rolling update.
3. If any configuration is manually modified on the cluster via `kubectl`, `selfHeal: true` automatically reverts it back to match the Git repository.

### Installation & Application Setup:
```bash
# 1. Automated installation script
./argocd/install-argocd.sh

# 2. Manual application manifest apply:
kubectl apply -f argocd/application.yaml

# 3. Access ArgoCD Web UI:
kubectl port-forward svc/argocd-server -n argocd 8443:443
```
- **URL**: `https://localhost:8443`
- **Username**: `admin`
- **Password**:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```

---

## 11. Troubleshooting & Verification Commands

### Port Allocation Reference (Zero Conflict):
| Component | Environment | Port | Access URL |
| :--- | :--- | :--- | :--- |
| **Jenkins** | Host System | **`8080`** | `http://localhost:8080` |
| **PetStore App** | Docker / Docker Compose | **`8082`** | `http://localhost:8082/jpetstore/` |
| **PetStore App** | Kubernetes (Port-Forward) | **`8082`** | `http://localhost:8082/jpetstore/` |
| **Helm Dashboard** | Web UI | **`8085`** | `http://localhost:8085` |
| **ArgoCD Dashboard** | GitOps Web UI | **`8443`** | `https://localhost:8443` |

### Check Kubernetes Workloads:
```bash
kubectl get pods,svc,ingress,hpa -n petstore
kubectl logs -f -l app=petstore -n petstore
```

### Port-Forward PetStore Application from Kubernetes:
```bash
kubectl port-forward svc/petstore-service 8082:80 -n petstore
```

---
*Developed & Maintained by Mukesh Chaudhary for Petstore_App DevOps & GitOps Automation.*
