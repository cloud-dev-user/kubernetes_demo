# Kubernetes Hands-on Repo — README

Welcome! This repository is a **step-by-step student guide** for hands-on labs covering:

- Deploying apps with `kubectl` and YAML manifests
- Scaling and rolling updates
- Self-healing with ReplicaSets and health checks

This document includes ready-to-use YAML manifests, step-by-step commands, verification steps, troubleshooting tips, and instructions for opening the repo **offline in VS Code**.

---

## Objectives

By the end of these labs you will be able to:

1. Deploy an app using declarative YAML manifests and `kubectl`.
2. Scale apps and perform rolling updates with zero downtime.
3. Observe Kubernetes self-healing via ReplicaSets and liveness/readiness probes.
4. Work with ConfigMaps and Secrets.
5. Use VS Code offline to edit and run the manifests (assuming you have access to a Kubernetes cluster or a browser-based playground).

---

## Prerequisites

You can run these labs in one of the following ways (pick one):

- **Browser-based playground (recommended for no-install labs):** Play with Kubernetes (https://labs.play-with-k8s.com) or Killercoda. These provide a web terminal with `kubectl` connected to a temporary cluster.
- **Local cluster (optional):** Minikube / kind / k3s + `kubectl` installed locally.

> Note: If you are using a browser playground, paste the YAML contents into files in the playground terminal (e.g. `cat > manifests/01-deployment.yaml <<'EOF' ... EOF`) or copy-paste the `kubectl apply -f -` approach.

---

## Repo structure (suggested)

```
k8s-hands-on-repo/
├─ README.md               <-- this guide
├─ manifests/
│  ├─ 01-deployment.yaml
│  ├─ 02-service.yaml
│  ├─ 03-configmap.yaml
│  ├─ 04-secret.yaml
│  ├─ 05-replicaset.yaml
│  └─ 06-health-checks-deployment.yaml
└─ labs/
   ├─ 1-deploy-and-verify.md
   ├─ 2-scaling-rolling-update.md
   └─ 3-self-healing.md
```

> All manifests are included below — copy them into the `manifests/` folder before applying, or apply them directly from the README using `kubectl apply -f -` with pasted YAML.

---

## Manifest: 01-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: my-config
        - secretRef:
            name: my-secret
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "250m"
            memory: "256Mi"
```

---

## Manifest: 02-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: NodePort
```

---

## Manifest: 03-configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  APP_MODE: "dev"
  WELCOME_MSG: "Hello from ConfigMap"
```

---

## Manifest: 04-secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  DB_PASSWORD: "pass123"
```

> `stringData` is convenient in examples; Kubernetes will convert to `data` (base64) internally.

---

## Manifest: 05-replicaset.yaml (direct ReplicaSet example)

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-rs
  template:
    metadata:
      labels:
        app: nginx-rs
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
```

> Note: ReplicaSets are normally managed by Deployments. This manifest is for demonstrating self-healing at the ReplicaSet level.

---

## Manifest: 06-health-checks-deployment.yaml

This Deployment demonstrates **liveness** and **readiness** probes. The liveness probe intentionally queries `/healthz` which **nginx** does not serve by default — this will illustrate automatic container restarts and self-healing. Use this carefully in shared environments (it can create restart loops).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-demo
  labels:
    app: health-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-demo
  template:
    metadata:
      labels:
        app: health-demo
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5
```

---

# LAB 1 — Deploying apps with `kubectl` and YAML manifests

### Goals
- Apply Deployment, Service, ConfigMap, Secret YAMLs
- Verify Pods are running and Service is reachable

### Steps
1. Create a `manifests/` folder and paste the YAML files above as `01-deployment.yaml`, `02-service.yaml`, `03-configmap.yaml`, `04-secret.yaml`.

2. Apply everything at once:

```bash
kubectl apply -f manifests/
```

_or_ apply single files:

```bash
kubectl apply -f manifests/03-configmap.yaml
kubectl apply -f manifests/04-secret.yaml
kubectl apply -f manifests/01-deployment.yaml
kubectl apply -f manifests/02-service.yaml
```

3. Verify resources:

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl describe deployment nginx-deployment
kubectl logs -l app=nginx --tail=50
```

4. Open the Service:
- In **Play with K8s**: the service NodePort will be visible as a clickable URL. Use `minikube service nginx-service --url` if working locally with Minikube.

Expected: `2` replicas running, Service exposes nginx on a NodePort.

---

# LAB 2 — Scaling and Rolling Updates

### Goals
- Scale the app horizontally
- Perform a rolling update (change image version)
- Roll back if needed

### Scaling (imperative):

```bash
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods -l app=nginx
```

### Scaling (declarative):
- Edit `manifests/01-deployment.yaml` and change `replicas: 2` to `replicas: 5` then:

```bash
kubectl apply -f manifests/01-deployment.yaml
```

### Rolling update (imperative):

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.21
kubectl rollout status deployment/nginx-deployment
kubectl get pods -l app=nginx
```

### Rolling update (declarative):
- Edit `manifests/01-deployment.yaml` container image to `nginx:1.21` and `kubectl apply -f manifests/01-deployment.yaml`.

### Check rollout history & rollback:

```bash
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment  # rollback to previous revision
kubectl rollout status deployment/nginx-deployment
```

Expected: New pods created with the updated image while old pods are terminated gradually. No downtime (service should remain reachable).

---

# LAB 3 — Self-healing with ReplicaSets and Health Checks

### Goals
- Demonstrate ReplicaSet auto-recreation of Pods
- Observe liveness & readiness behavior

### ReplicaSet self-heal

```bash
kubectl apply -f manifests/05-replicaset.yaml
kubectl get pods -l app=nginx-rs
# Delete one pod
kubectl delete pod <one-of-the-pod-names>
# Watch the ReplicaSet create a replacement
kubectl get pods -w
```

Expected: ReplicaSet immediately starts a replacement Pod so that `replicas: 2` is maintained.

### Liveness & readiness probes demonstration

```bash
kubectl apply -f manifests/06-health-checks-deployment.yaml
kubectl get pods -l app=health-demo
kubectl describe pod -l app=health-demo
kubectl logs -l app=health-demo --follow
```

Because the liveness probe checks `/healthz` (which nginx does not serve), the container will fail the probe and Kubernetes will **restart** the container (CrashLoop/BackOff or rapid restarts). Use `kubectl describe pod <pod>` to see `Liveness probe failed` events.

To stop the restart-loop, delete the health-demo deployment:

```bash
kubectl delete deployment health-demo
```

> Tip: In real apps, point probes at real endpoints that return `200` when healthy. Use `startupProbe` for slow-starting containers to avoid false restarts.

---

# Cleanup (remove resources)

```bash
kubectl delete -f manifests/02-service.yaml
kubectl delete -f manifests/01-deployment.yaml
kubectl delete -f manifests/03-configmap.yaml
kubectl delete -f manifests/04-secret.yaml
kubectl delete -f manifests/05-replicaset.yaml
kubectl delete -f manifests/06-health-checks-deployment.yaml
# or remove whole folder at once
kubectl delete -f manifests/
```

---

# Troubleshooting & tips

- **ImagePullBackOff**: Check image name/tag and network access.
- **CrashLoopBackOff**: `kubectl logs <pod>` and `kubectl describe pod <pod>` to inspect errors. Check probes.
- **Service not reachable**: Check `kubectl get svc` and `kubectl describe svc <svc>`. If NodePort, ensure you open the correct Node IP:NodePort.
- **Pod not starting**: Check events via `kubectl describe pod`.

---

# How to open this GitHub repo **offline** in VS Code (step-by-step)

> These instructions assume you have the repo files on your local machine (either cloned from GitHub or downloaded as a ZIP).

1. **Download / clone the repo**
   - Clone (if you pushed it to GitHub):
     ```bash
     git clone https://github.com/<your-username>/k8s-hands-on-repo.git
     cd k8s-hands-on-repo
     ```
   - Or, if you received the repo as a ZIP: unzip it and `cd` into the directory.

2. **Open the folder in VS Code**
   - From terminal:
     ```bash
     code .
     ```
   - Or from VS Code: `File → Open Folder...` and select the repo folder.

3. **Recommended VS Code extensions** (install from the Extensions pane):
   - **Kubernetes** (ms-kubernetes-tools.vscode-kubernetes-tools) — cluster explorer, apply manifests, view resources
   - **YAML** (redhat.vscode-yaml) — YAML validation & auto-complete
   - **Docker** (ms-azuretools.vscode-docker) — optional, helpful when working with images
   - **GitLens** — optional, useful for git history & collaboration

4. **Edit manifests**
   - Open files under `manifests/` and modify images, resource requests, probe paths, etc.

5. **Apply manifests from VS Code**
   - Use the integrated terminal (``Ctrl+` ``) and run `kubectl apply -f manifests/`
   - If you installed the Kubernetes extension, use the extension's context menu (right-click a YAML file → `Kubernetes: Apply`) to apply directly to your current kubeconfig context.

6. **If you don't have a local Kubernetes cluster but still want to use VS Code to edit**
   - You can edit files offline in VS Code and later copy them into a browser-playground terminal (Play with K8s) and `kubectl apply -f -` with pasted contents.

---

# Optional: Create a GitHub repo and push (quick steps)

1. Create a new empty repository on GitHub (e.g., `k8s-hands-on-repo`).
2. Push local folder:

```bash
git init
git add .
git commit -m "Initial commit: k8s hands-on manifests and guide"
git branch -M main
git remote add origin https://github.com/<your-username>/k8s-hands-on-repo.git
git push -u origin main
```

---

If you want, I can:
- Convert this README + manifests into a ready-to-download ZIP file, or
- Create the repository on GitHub for you (I can provide the `git` commands and the repo contents so you can copy/paste), or
- Produce a one-page printable PDF lab handout.

Tell me which of these you'd like next and I'll prepare it.

