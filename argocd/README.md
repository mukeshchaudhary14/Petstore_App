# ArgoCD GitOps Setup for PetStore Application

This directory contains the GitOps manifests and automation scripts for deploying the Petstore application to Kubernetes using ArgoCD.

---

## 🏗 GitOps Architecture

```
+---------------------------+        +-------------------+        +--------------------+
|   GitHub Repository       | -----> |   Argo CD         | -----> |   Kubernetes       |
|  (mukeshchaudhary14/      |  Sync  |  (argocd namespace) |  Apply |  Cluster           |
|   Petstore_App)           |        |                   |        |  (petstore ns)     |
+---------------------------+        +-------------------+        +--------------------+
```

Whenever changes are pushed to `helm/petstore` or `k8s/` in Git, ArgoCD detects the diff and automatically syncs the cluster state.

---

## 🚀 Quick Setup Instructions

### 1. Automated Installation
Run the provided setup script:
```bash
./argocd/install-argocd.sh
```

---

### 2. Manual Step-by-Step Installation

1. **Create ArgoCD Namespace & Install:**
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Wait for ArgoCD Server to be Ready:**
   ```bash
   kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
   ```

3. **Retrieve the Initial Admin Password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
   ```

4. **Port-Forward ArgoCD Web UI:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Open `https://localhost:8080` in your browser (username: `admin`).

5. **Deploy the PetStore Application Manifest:**
   - **Using Helm Chart (Recommended):**
     ```bash
     kubectl apply -f argocd/application.yaml
     ```
   - **Using Raw K8s Manifests:**
     ```bash
     kubectl apply -f argocd/application-k8s.yaml
     ```

---

## ⚙ Application Manifest Details (`application.yaml`)

- **Repository**: `https://github.com/mukeshchaudhary14/Petstore_App.git`
- **Path**: `helm/petstore`
- **Target Revision**: `HEAD` (tracks latest commit)
- **Destination Namespace**: `petstore`
- **Automated Sync**:
  - `prune: true` (removes obsolete k8s resources when deleted from Git)
  - `selfHeal: true` (reverts manual changes made via kubectl to match Git)
  - `CreateNamespace=true` (creates `petstore` namespace automatically)
