# Registry Mirror Helm Chart

A Helm chart for deploying multiple Docker registry pull-through cache mirrors on Kubernetes. Define your mirrors once in `values.yaml` and the chart generates all the required Deployments, Services, ConfigMaps, Ingresses, and PVCs.

## Features

- **Multi-registry support** -- mirror Docker Hub, GHCR, Quay, and any OCI-compatible registry from a single release
- **Cascading defaults** -- set resource limits, image, replicas, and other settings once; override per mirror as needed
- **Optional Ingress & Persistence** -- enable per mirror or globally via defaults

## Prerequisites

- Kubernetes >= 1.25
- Helm >= 3.x

## Quick Start

```bash
helm repo add registry-mirror https://aminmokhtari94.github.io/registry-mirror/
helm repo update

helm install my-mirrors registry-mirror/registry-mirror
```

## Configuration

All configuration lives in `values.yaml`. The chart uses a **defaults + per-mirror override** pattern:

| Key | Description | Default |
|-----|-------------|---------|
| `defaults.image` | Registry container image | `docker.arvancloud.ir/registry:2` |
| `defaults.replicaCount` | Replicas per mirror | `1` |
| `defaults.resources` | CPU/memory requests & limits | 100m/128Mi req, 500m/512Mi limit |
| `defaults.env` | Extra environment variables | `[]` |
| `defaults.ingress.enabled` | Enable Ingress globally | `false` |
| `defaults.persistence.enabled` | Enable PVC globally | `false` |
| `defaults.persistence.size` | PVC size | `50Gi` |

### Defining Mirrors

```yaml
mirrors:
  - name: dockerhub
    remoteURL: https://registry-1.docker.io
    ingress:
      host: dockerhub.mirror.local

  - name: ghcr
    remoteURL: https://ghcr.io
    ingress:
      host: ghcr.mirror.local

  - name: quay
    remoteURL: https://quay.io
    # per-mirror override
    replicaCount: 2
    resources:
      limits:
        cpu: 1
        memory: 1Gi
```

Each mirror entry generates its own Deployment, Service, ConfigMap, and optionally an Ingress and PVC.

### Proxy & Environment Variables

If your cluster requires an outbound proxy (e.g. for pulling from upstream registries behind a firewall), set it via `defaults.env`:

```yaml
defaults:
  env:
    - name: HTTPS_PROXY
      value: http://v2raya.default.svc.cluster.local:20172
    - name: NO_PROXY
      value: 10.0.0.0/8
    - name: REGISTRY_STORAGE_DELETE_ENABLED
      value: "true"
```

These are injected into every mirror container. Override per mirror by setting `env` on the mirror entry.

### Enabling Ingress

```yaml
defaults:
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-arvan
      # Allow unlimited body size for large image layers
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      # Extended timeouts for large layer pulls
      nginx.ingress.kubernetes.io/proxy-read-timeout: "1200"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "1200"
      nginx.ingress.kubernetes.io/send-timeout: "1200"
      # Disable buffering for streaming large blobs
      nginx.ingress.kubernetes.io/proxy-buffering: "off"
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
      # Disable rate limiting
      nginx.ingress.kubernetes.io/limit-connections: "0"
      nginx.ingress.kubernetes.io/limit-rps: "0"
      nginx.ingress.kubernetes.io/limit-rpm: "0"
      # Retry on upstream errors
      nginx.ingress.kubernetes.io/proxy-next-upstream: "error timeout http_502 http_503 http_504"
      nginx.ingress.kubernetes.io/proxy-next-upstream-tries: "3"
    tls:
      - secretName: sub-kiz-ir-tls
        hosts:
          - "*.kiz.ir"
```

Then set `host` per mirror. The TLS wildcard and annotations are inherited from defaults.

### Enabling Persistence

```yaml
defaults:
  persistence:
    enabled: true
    size: 50Gi
    storageClass: ceph-block
    accessModes:
      - ReadWriteMany
```

### Full Example

A production-ready setup mirroring six registries behind a wildcard domain with TLS, proxy, and nginx-ingress:

```yaml
defaults:
  image: docker.arvancloud.ir/registry:2
  replicaCount: 1
  env:
    - name: HTTPS_PROXY
      value: http://v2raya.default.svc.cluster.local:20172
    - name: NO_PROXY
      value: 10.0.0.0/8
    - name: REGISTRY_STORAGE_DELETE_ENABLED
      value: "true"
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-arvan
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "1200"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "1200"
    tls:
      - secretName: sub-kiz-ir-tls
        hosts:
          - "*.kiz.ir"

mirrors:
  - name: dockerhub
    remoteURL: https://registry-1.docker.io
    ingress:
      host: docker.kiz.ir

  - name: quay
    remoteURL: https://quay.io
    image: docker.arvancloud.ir/registry:2.5  # per-mirror image override
    ingress:
      host: quay.kiz.ir

  - name: gcr
    remoteURL: https://gcr.io
    ingress:
      host: gcr.kiz.ir

  - name: ghcr
    remoteURL: https://ghcr.io
    ingress:
      host: ghcr.kiz.ir

  - name: k8s
    remoteURL: https://k8s.gcr.io
    ingress:
      host: k8s.kiz.ir

  - name: gitlab
    remoteURL: https://registry.gitlab.com
    ingress:
      host: gitlab.kiz.ir
```

## Installing from Source

```bash
git clone https://github.com/aminmokhtari94/registry-mirror.git
cd registry-mirror
helm install my-mirrors .
```

## License

MIT
