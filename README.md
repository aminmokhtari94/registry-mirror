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

### Enabling Persistence

```yaml
defaults:
  persistence:
    enabled: true
    size: 100Gi
    storageClass: fast-ssd
```

### Enabling Ingress

```yaml
defaults:
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
```

Then set `host` (and optionally `tls`) per mirror.

## Installing from Source

```bash
git clone https://github.com/aminmokhtari94/registry-mirror.git
cd registry-mirror
helm install my-mirrors .
```

## License

MIT
