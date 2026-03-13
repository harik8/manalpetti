
# GitHub Workflows

Reusable CI/CD workflows designed to support both monorepo and unirepo architectures.

## Architecture

These workflows are built as modular, reusable components that can be called from any repository:

```
┌────────────────┐
│  Your Workflow      │  (in your repo)
└──────────┬──────────┘
           │
           ├──► INIT (rw-init.yaml)    - Detect modified apps
           │
           ├──► CI (rw-ci.yaml)        - Build & test Docker images
           │
           └──► CD (rw-cd.yaml)        - Deploy to Kubernetes
```

## Key Features

✅ **Monorepo Support** - Automatically detects and builds only modified apps
✅ **Unirepo Support** - Works with single-app repositories
✅ **Reusable** - Call from any workflow in any repository
✅ **Flexible** - Configurable depth for nested directory structures
✅ **Secure**  Trivy and Hadolint
✅ **Smart Tagging** - Automatic version detection from Dockerfile or git

---

## Workflows

### 1. `rw-init.yaml` - Initialization

**Purpose:** Detects which applications were modified in the last commit.

**Type:** Reusable workflow

**Inputs:**

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `apps_path` | string | Repository name | Path pattern to match applications |
| `apps_path_depth` | string | `2` | Directory depth level |

**Outputs:**

| Output | Description | Example |
|--------|-------------|---------|
| `apps_modified` | JSON array of modified app paths | `["apps/whoami", "apps/api"]` |

**How it works:**
1. Fetches last 2 commits
2. Runs `git diff` to find changed files
3. Filters by `apps_path` pattern
4. Extracts unique directories based on `apps_path_depth`
5. Returns JSON array of modified apps

**Depth Examples:**
- `apps_path_depth: 2` → Matches `apps/whoami` from `apps/whoami/src/main.go`
- `apps_path_depth: 3` → Matches `addons/custom/runner` from `addons/custom/runner/Dockerfile`

**Usage:**
```yaml
jobs:
  init:
    uses: ./.github/workflows/rw-init.yaml
    with:
      apps_path: 'apps'
      apps_path_depth: 2
```

---

### 2. `rw-ci.yaml` - Continuous Integration

**Purpose:** Builds, scans, and pushes Docker images for modified applications.

**Type:** Reusable workflow

**Inputs:**

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `apps_modified` | string | No | Repository name | JSON array of apps to build |
| `apps_path_depth` | string | No | `2` | Directory depth for app name extraction |
| `build_args` | string | No | `""` | Docker build arguments |

**Outputs:**

| Output | Description | Example |
|--------|-------------|---------|
| `tag` | Generated Docker image tag | `main-a1b2c` or `1.2.3` |

**Secrets:**

| Secret | Required | Description |
|--------|----------|-------------|
| `DOCKER_PASSWORD` | Yes | Docker Hub password |

**Pipeline Steps:**

1. **Checkout** - Clone repository
2. **Setup Docker Buildx** - Configure multi-platform builds
3. **Set Build Context** - Determine Dockerfile location
   - Root repo: Uses `.` as context
   - Monorepo: Uses app directory as context
4. **Set Image Tag** - Generate version tag:
   - Checks for `ENV VERSION=` in Dockerfile
   - Falls back to branch/tag name + short SHA
5. **Set App Name** - Extract app name from path
6. **Hadolint** - Lint Dockerfile (non-blocking)
7. **Docker Login** - Authenticate to Docker Hub
8. **Build & Push** - Build and push image
   - Platform: `linux/amd64`
   - Skipped if PR has `ci-skippush` label
9. **Trivy Scan** - Security vulnerability scan
   - Severity: CRITICAL, HIGH
   - Non-blocking

**Image Tagging Logic:**

```
Pull Request:
  - With VERSION: {VERSION}-{short-sha}
  - Without VERSION: {branch}-{short-sha}

Push/Merge:
  - With VERSION: {VERSION}
  - Without VERSION: {branch}-{short-sha}
```

**Examples:**
- PR with VERSION: `gha-runner:2.320.0-a1b2c`
- PR without VERSION: `whoami:feature-auth-a1b2c`
- Push with VERSION: `gha-runner:2.320.0`
- Push without VERSION: `whoami:main-d3e4f`

**Usage:**
```yaml
jobs:
  ci:
    needs: init
    uses: ./.github/workflows/rw-ci.yaml
    with:
      apps_modified: ${{ needs.init.outputs.apps_modified }}
      apps_path_depth: 2
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

---

### 3. `rw-cd.yaml` - Continuous Deployment

**Purpose:** Deploys applications to Kubernetes using Helm.

**Type:** Reusable workflow

**Inputs:**

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `appsJSON array of apps to deploy |
| `apps_path_depth` | string | No | `2` | Directory depth for app name |
| `stage` | string | No | `sandbox` | Deployment environment |
| `tag` | string | Yes | - | Docker image tag to deploy |

**Secrets:**

| Secret | Required | Description |
|--------|----------|-------------|
| `DOCKER_PASSWORD` | Yes | Docker Hub password |

**Runner:** `self-hosted` (requires self-hosted runner with kubectl/helm access)

**Pipeline Steps:**

1. **Checkout** - Clone repository
- Install latest Helm
3. **Set App Name** - Extract app name from path
4. **Deploy** - Deploy using Helm:
   - Updates Chart.yaml with app name and version
tiple sources
   - Creates namespace if needed
   - Enables automatic rollback on failure

**Helm Values Hierarchy:**

```
Base Template (lowest priority)
  ↓
.helm-tmpl/values.yaml
  ↓
App-Specific Values
  ↓
{app}/.helm/values.yaml
  ↓
Environment-Specific Values (highest priority)
  ↓
{app}/.helm/{stage}/values.yaml
```

**Helm Command:**
```bash
helm upgrade --install --rollback-on-failure \
  --create-namespace \
  --namespace {app-name} \
  --set image.repository={DOCKER_USERNAME}/{app-name} \
  --set image.tag={tag} \
  -f .helm-tmpl/values.yaml \
  -f {app}/.helm/values.yaml \
  -f {app}/.helm/{stage}/values.yaml \
  {app-name} .helm-tmpl
```

**Skip Deployment:**
Add `ci-skippush` label to PR to skip both push and deployment.

**Usage:**
```yaml
jobs:
  cd:
    needs: [init, ci]
    uses: ./.github/workflows/rw-cd.yaml
    with:
      apps_modified: ${{ needs.init.outputs.apps_modified }}
      tag: ${{ needs.ci.outputs.tag }}
      stage: production
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

---

## Complete Pipeline Example

### Monorepo Setup

```yaml
# .github/workflows/deploy.yaml
name: Deploy Apps

on:
  push:
    branches: [main, dev]
    paths:
      - 'apps/**'

jobs:
  init:
    uses: ./.github/workflows/rw-init.yaml
    with:
      apps_path: 'apps'
      apps_path_depth: 2

  ci:
    needs: init
    uses: ./.github/workflows/rw-ci.yaml
    with:
      apps_modified: ${{ needs.init.outputs.apps_modified }}
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}

  cd:
    needs: [init, ci]
    uses: ./.github/workflows/rw-cd.yaml
    with:
      apps_modified: ${{ needs.init.outputs.apps_modified }}
      tag: ${{ needs.ci.outputs.tag }}
      stage: sandbox
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

### Unirepo Setup

```yaml
# .github/workflows/deploy.yaml
name: Deploy App

on:
  push:
    branches: [main]

jobs:
  init:
    uses: ./.github/workflows/rw-init.yaml
    # Uses default: repository name

  ci:
    needs: init
    uses: ./.github/workflows/rw-ci.yaml
    with:
      apps_modified: ${{ needst.outputs.apps_modified }}
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}

  cd:
    needs: [init, ci]
    uses: ./.github/workflows/rw-cd.yaml
    with:
      apps_modified: ${{ needs.init.outputs.apps_modified }}
      tag: ${{ needs.ci.outputs.tag }}
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

### Nested Monorepo (3-level depth)

```yaml
# For structure: addons/custom/app-name
jobs:
  init:
    uses: ./.github/workflows/rw-init.yaml
    with:
 'addons/custom'
      apps_path_depth: 3

  ci:
    needs: init
    uses: ./.github/workflows/rw-ci.yaml
    with:
      apps_modified: ${{ needs.init.outputs.apps_modified }}
      apps_path_depth: 3
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```