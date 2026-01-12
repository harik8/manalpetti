# GitHub Actions Workflows

This directory contains reusable and orchestration workflows for automated CI/CD pipelines.

## Workflow Architecture

The workflows follow a modular, composable design with three layers:

1. **Base Workflows** (`rw-base-*`) - Core reusable components
2. **Composite Workflows** (`rw-composite-*`) - Orchestrate base workflows
3. **Entry Workflows** (`ci.yaml`, `cicd.yaml`) - Trigger workflows on git events

## Workflows

### Entry Point Workflows

#### [`ci.yaml`](ci.yaml)
**Purpose:** Build and test Docker images on push/PR

**Triggers:**
- Push to `main` branch
- Pull requests to `main` branch
- Only when files under `images/**` change

**Calls:** `rw-composite-ci.yaml` with `src_path: 'images'`

---

#### [`cicd.yaml`](cicd.yaml)
**Purpose:** Full CI/CD pipeline for applications
    
**Triggers:**
- Push to `main` branch
- Pull requests to `main` branch

**Calls:** `rw-composite-cicd.yaml` with `src_path: 'apps'`

---

### Composite Workflows

#### [`rw-composite-ci.yaml`](rw-composite-ci.yaml)
**Purpose:** Orchestrates initialization and build process

**Jobs:**
1. `INIT` - Detects changed modules
2. `CI` - Builds Docker images for changed modules

**Inputs:**
- `src_path` (string, optional) - Path filter for source code

**Outputs:**
- `modules_changed` - List of modules that were modified
- `tag` - Docker image tag from build

**Secrets:**
- `DOCKER_PASSWORD` (required)

---

#### [`rw-composite-cicd.yaml`](rw-composite-cicd.yaml)
**Purpose:** Complete CI/CD pipeline orchestration

**Jobs:**
1. `COMPOSITE_CI` - Builds images
2. `CD` - Deploys to environment

**Inputs:**
- `src_path` (string, optional) - Path filter for source code

**Secrets:**
- `DOCKER_PASSWORD` (required)

---

### Base Workflows

#### [`rw-base-init.yaml`](rw-base-init.yaml)
**Purpose:** Detect changed modules from git diff

**How it works:**
- Compares HEAD with HEAD~ (last commit)
- Filters changes matching `src_path` pattern
- Extracts first two path segments (e.g., `apps/app1`)
- Returns unique list as JSON array

**Inputs:**
- `src_path` (string, optional) - Path pattern to filter changes
  - Default: repository name

**Outputs:**
- `modules_changed` - JSON array of changed module paths

**Example output:**
```json
["apps/whoami", "apps/app2"]
```

---

#### [`rw-base-ci.yaml`](rw-base-ci.yaml)
**Purpose:** Build and push Docker images

**Jobs:**
- Matrix strategy builds each changed module in parallel
- Sets up Docker Buildx
- Builds and tags images
- Pushes to container registry

**Inputs:**
- `modules_changed` (string, required) - JSON array of modules to build
- `build_args` (string, optional) - Docker build arguments

**Outputs:**
- `tag` - Docker image tag

**Secrets:**
- `DOCKER_PASSWORD` (required)

**Conditions:**
- Skips if `modules_changed` is empty (`[]`)

---

#### [`rw-base-cd.yaml`](rw-base-cd.yaml)
**Purpose:** Deploy applications using Helm

**Jobs:**
- Matrix deploys each changed module in parallel
- Updates Helm chart with new image tag
- Runs `helm upgrade --install`

**Inputs:**
- `modules_changed` (string, required) - JSON array of modules to deploy
- `tag` (string, required) - Docker image tag to deploy

**Secrets:**
- `DOCKER_PASSWORD` (required)

**Conditions:**
- Skips if PR has `ci-skippush` label

**Runner:** `self-hosted`

---

## Typical Flow

### For Apps (Full CICD)
```
Push/PR → cicd.yaml
           ↓
        rw-composite-cicd.yaml
           ↓
        ┌──────────────┬──────────────┐
        ↓              ↓              ↓
   rw-base-init   rw-base-ci    rw-base-cd
```

1. Detect changed apps under `apps/`
2. Build Docker images for changed apps
3. Deploy to environment

### For Images (CI Only)
```
Push/PR (images/**) → ci.yaml
                       ↓
                  rw-composite-ci.yaml
                       ↓
                  ┌────────────┬────────────┐
                  ↓            ↓
             rw-base-init  rw-base-ci
```

1. Detect changed images under `images/`
2. Build Docker images

---

## Usage Examples

### Using Composite CICD in Another Repo
```yaml
name: Deploy App
on: [push]

jobs:
  deploy:
    uses: manalpetti/.github/workflows/rw-composite-cicd.yaml@main
    with:
      src_path: 'services'
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

### Using Base CI Directly
```yaml
jobs:
  build:
    uses: manalpetti/.github/workflows/rw-base-ci.yaml@main
    with:
      modules_changed: '["apps/app1", "apps/app2"]'
      build_args: "ENV=prod"
    secrets:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

---

## Configuration

### Required Secrets
- `DOCKER_PASSWORD` - Docker registry authentication

### Required Permissions
```yaml
permissions:
  id-token: write  # JWT for authentication
  contents: read   # Repository checkout
```

### Runners
- Most workflows: `ubuntu-latest` or `ubuntu-slim`
- CD workflow: `self-hosted` (for deployment access)

---

## Naming Conventions

- `rw-base-*` - Reusable workflow, base component
- `rw-composite-*` - Reusable workflow, composite/orchestration
- Lowercase descriptive names for entry workflows

---

## Module Detection Logic

The `rw-base-init.yaml` workflow detects changes at the **second-level directory**:

```bash
apps/whoami/src/index.html     → apps/whoami
apps/app2/Dockerfile           → apps/app2
images/gha-runner/entrypoint.sh → images/gha-runner
```

This ensures entire modules are built/deployed when any file within them changes.
