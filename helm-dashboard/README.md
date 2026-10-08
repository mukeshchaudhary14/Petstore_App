# Komodor Helm Dashboard Setup Guide

Helm Dashboard (`komodorio/helm-dashboard`) is an open-source graphical user interface for visualizing, deploying, and managing Helm charts and releases in your Kubernetes cluster.

---

## 🚀 Quick Start Options

### Option 1: Run via Helm CLI Plugin (Easiest for local development)
1. Install the Helm Dashboard plugin:
   ```bash
   helm plugin install https://github.com/komodorio/helm-dashboard
   ```
2. Launch the dashboard:
   ```bash
   helm dashboard --port 8080 --bind 0.0.0.0
   ```
3. Open your browser at: `http://localhost:8080`

---

### Option 2: Run via Docker
If you do not want to install plugins locally:
```bash
docker run --rm -it \
  --name helm-dashboard \
  -p 8080:8080 \
  -v ~/.kube/config:/root/.kube/config:ro \
  ghcr.io/komodorio/helm-dashboard:latest \
  --bind=0.0.0.0 --port=8080
```
Open `http://localhost:8080` in your browser.

---

### Option 3: Deploy In-Cluster (Production / Remote Clusters)
To run Helm Dashboard directly inside your Kubernetes cluster:

1. **Apply the RBAC & Namespace:**
   ```bash
   kubectl apply -f helm-dashboard/k8s/rbac.yaml
   ```

2. **Deploy the Helm Dashboard Pod & Service:**
   ```bash
   kubectl apply -f helm-dashboard/k8s/deployment.yaml
   ```

3. **Access via Port-Forwarding:**
   ```bash
   kubectl port-forward svc/helm-dashboard-service -n helm-dashboard 8080:8080
   ```
   Open `http://localhost:8080` in your browser.

---

## 🛠 Features in Helm Dashboard
- **Installed Charts**: See all deployed Helm releases across namespaces (`petstore`, `argocd`, `default`).
- **Revision History**: Inspect release revisions, commit diffs, and rollback with a single click.
- **Values Inspection**: View active `values.yaml` and computed user values.
- **Manifest View**: Check raw Kubernetes manifests rendered by Helm.
- **Repository Management**: Search and install charts directly from Artifact Hub or private chart repositories.
