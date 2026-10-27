# Intern Task App – Docker & Kubernetes

A lightweight, dependency-free Python HTTP application containerized using Docker and deployed to a local Kubernetes cluster using kind.

## Project Structure

```text
intern-task-app/
├── app/
│   └── app.py
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── Dockerfile
└── README.md
```

## Application Endpoints

| Endpoint | Response |
|---|---|
| `/` | `hello from intern-task` |
| `/healthz` | `ok` |

The application listens on port `5000` by default and supports configuration through the `PORT` environment variable.

## Running with Docker

Build the Docker image:

```bash
docker build -t intern-task-app:local .
```

Run the container:

```bash
docker run --rm -p 8080:8080 -e PORT=8080 intern-task-app:local
```

Verify in another terminal:

```bash
curl localhost:8080/healthz
curl localhost:8080/
```

Expected output:

```text
ok
hello from intern-task
```

## Kubernetes Deployment

Create a kind cluster:

```bash
kind create cluster --name intern-task
```

Load the locally built image:

```bash
kind load docker-image intern-task-app:local --name intern-task
```

Deploy the application:

```bash
kubectl apply -f k8s/
```

Verify deployment status:

```bash
kubectl rollout status deployment/intern-task-app --timeout=60s
kubectl get pods
kubectl get svc
```

Forward the Service port:

```bash
kubectl port-forward svc/intern-task-app 8080:80
```

In another terminal, verify both endpoints:

```bash
curl -sf localhost:8080/healthz
curl -sf localhost:8080/
```

Expected output:

```text
ok
hello from intern-task
```

## Design Decisions

- **Base image:** `python:3.12-slim` provides a lightweight Python runtime without unnecessary dependencies.
- **Non-root user:** The application runs as a dedicated non-root user (UID 10001) to improve container security.
- **Image pull policy:** `Never` ensures Kubernetes uses the locally loaded Docker image without attempting to pull from an external registry.
- **Readiness probe:** Checks `/healthz` to ensure the HTTP server responds before the Pod receives traffic.
- **Liveness probe:** Checks `/healthz` and restarts the container after repeated failures. These probes detect HTTP server failures but do not check deeper dependencies.
- **Port consistency:** The application, Deployment, and health probes use port `5000`. The ClusterIP Service exposes port `80` and forwards traffic to port `5000`.

## Cleanup

Delete Kubernetes resources:

```bash
kubectl delete -f k8s/
```

Delete the kind cluster:

```bash
kind delete cluster --name intern-task
```