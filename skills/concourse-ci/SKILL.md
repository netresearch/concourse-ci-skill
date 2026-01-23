---
name: concourse-ci
description: This skill provides expert guidance for Concourse CI pipeline development and should be used when creating pipelines, writing CI/CD YAML for Concourse, optimizing pipeline performance, debugging build failures, upgrading Concourse configurations, refactoring pipeline YAML, configuring git-resource or registry-image-resource, troubleshooting tag detection issues, working with fly CLI commands, implementing YAML anchors for DRY configuration, setting up webhook triggers, using set_pipeline for dynamic pipelines, or any task involving Concourse CI jobs, tasks, resources, or resource types.
version: 1.0.0
---

# Concourse CI Pipeline Development

This skill provides expert guidance for writing, refactoring, upgrading, and optimizing Concourse CI pipelines. Concourse is a pipeline-based continuous thing-doer that implements CI/CD workflows as dependency flows.

> **Compatibility**: Concourse v8.0+ (current). Legacy support for v6.5+ where noted.

## Core Concepts

### Pipeline Architecture

```
Pipeline
├── resources         # External versioned artifacts (git repos, images, buckets)
├── resource_types    # Custom resource type definitions
├── jobs              # Sequences of steps that process resources
│   └── steps         # get, put, task, set_pipeline, in_parallel, do, try
├── groups            # UI organization (optional)
└── var_sources       # Variable sources for credentials
```

### Key Design Principles

1. **Container-Native**: All execution occurs in containers
2. **Self-Contained**: Resource types defined within pipeline config
3. **Idempotent Jobs**: Loosely-coupled design for maintainability
4. **Deterministic Tasks**: Same inputs → same outputs

## Pipeline Creation Workflow

### 1. Define Resources

```yaml
resources:
- name: source-repo
  type: git
  icon: gitlab  # Material Design icon
  check_every: 5m
  source:
    uri: https://github.com/org/repo.git
    branch: main
    username: ((git.username))
    password: ((git.token))

- name: app-image
  type: registry-image
  icon: docker
  source:
    repository: registry.example.com/org/app
    username: ((registry.username))
    password: ((registry.password))
    tag: latest

# Webhook-triggered resource (instant checks instead of polling)
- name: source-webhook
  type: git
  webhook_token: ((webhook.secret))  # Trigger: POST /api/v1/teams/TEAM/pipelines/PIPE/resources/source-webhook/check/webhook?webhook_token=SECRET
  check_every: never  # Disable polling, rely on webhooks
  source:
    uri: https://github.com/org/repo.git
    branch: main
```

### 2. Define Jobs

```yaml
jobs:
- name: build
  serial: true
  plan:
  - get: source-repo
    trigger: true
  - task: compile
    file: source-repo/ci/tasks/compile.yml
  - put: app-image
    params:
      image: build-output/image.tar
```

### 3. Use YAML Anchors for DRY

```yaml
# Define reusable snippets at top
git-source: &git-source
  uri: ((git.uri))
  username: ((git.username))
  password: ((git.password))

notification: &notify-failure
  put: slack
  params:
    text: "Build failed: $BUILD_PIPELINE_NAME/$BUILD_JOB_NAME"

resources:
- name: repo-main
  type: git
  source:
    <<: *git-source
    branch: main

jobs:
- name: test
  plan:
  - get: repo-main
    trigger: true
  - task: run-tests
    file: repo-main/ci/tasks/test.yml
  on_failure:
    <<: *notify-failure
```

## Job Lifecycle Hooks

```yaml
jobs:
- name: deploy
  plan:
  - get: app-image
    trigger: true
    passed: [build]
  - task: deploy
    file: source-repo/ci/tasks/deploy.yml
  on_success:
    put: notify
    params: { text: "Deploy succeeded" }
  on_failure:
    put: notify
    params: { text: "Deploy failed" }
  on_error:
    put: notify
    params: { text: "Deploy errored" }
  on_abort:
    put: notify
    params: { text: "Deploy aborted" }
  ensure:
    task: cleanup
    file: source-repo/ci/tasks/cleanup.yml
```

### Hook Semantics

| Hook | Triggers When | Use Case |
|------|---------------|----------|
| `on_success` | Step/job succeeds | Success notifications, promotions |
| `on_failure` | Step/job fails (non-zero exit) | Alert teams, rollback |
| `on_error` | Infrastructure error (container crash, timeout) | Page on-call, investigate |
| `on_abort` | Build manually aborted or interrupted | Cleanup partial state |
| `ensure` | Always runs regardless of outcome | Release locks, cleanup resources |

**Important**: `on_failure` ≠ `on_error`. A task returning exit code 1 triggers `on_failure`. A container OOM kill or timeout triggers `on_error`. Handle both for robust pipelines.

## Step Types Quick Reference

| Step | Purpose | Example |
|------|---------|---------|
| `get` | Fetch resource version | `get: source-repo` |
| `put` | Update/push resource | `put: app-image` |
| `task` | Execute containerized work | `task: build` |
| `set_pipeline` | Dynamic pipeline config | `set_pipeline: feature-pipeline` |
| `in_parallel` | Concurrent execution | `in_parallel: [step1, step2]` |
| `do` | Sequential steps | `do: [step1, step2]` |
| `try` | Continue on failure | `try: { task: optional }` |
| `load_var` | Runtime variable | `load_var: version` |

## Variable Syntax

```yaml
# Basic variable reference
uri: ((git.uri))

# With field access
password: ((vault:secret/git.password))

# Local scope (from load_var)
tag: ((.version))
```

## Common Patterns

### Build-Test-Release Pipeline

```yaml
jobs:
- name: build
  plan:
  - get: source
    trigger: true
  - task: build
    file: source/ci/tasks/build.yml
  - put: image-rc
    params:
      image: build/image.tar
      tag: release-candidate

- name: test
  plan:
  - get: image-rc
    passed: [build]
    trigger: true
  - get: source
    passed: [build]
  - task: integration-tests
    file: source/ci/tasks/test.yml

- name: release
  plan:
  - get: image-rc
    passed: [test]
    trigger: true
  - get: source
    passed: [test]
  - put: image-release
    params:
      image: image-rc/image.tar
      version: source/version
```

### Parallel Execution

```yaml
- in_parallel:
    limit: 3  # Max concurrent steps
    fail_fast: true
    steps:
    - task: unit-tests
    - task: lint
    - task: security-scan
```

## Optimization Techniques

1. **Parallel Steps**: Use `in_parallel` for independent operations
2. **Task Caching**: Define `caches` for dependency directories
3. **Resource Filtering**: Use `paths`/`ignore_paths` to limit triggers
4. **Shallow Clones**: Set `depth: 1` for git resources when history not needed
5. **Serial Groups**: Prevent resource contention with `serial_groups`

## Critical Gotchas

### Git Resource Tag Detection Issue

**Problem**: After force-pushing a branch, Concourse may not detect new tags.

**Root Causes**:
1. Tags pointing to commits no longer reachable from tracked branch
2. Mixed read/write on same git resource creates version conflicts
3. Unescaped regex dots (`.` matches any character)

**Solutions**:

```yaml
# 1. Escape regex dots properly
tag_regex: "^v[0-9]+\\.[0-9]+\\.[0-9]+$"

# 2. Enable tag cleanup
resources:
- name: repo
  type: git
  source:
    uri: ((git.uri))
    branch: main
    tag_regex: "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    fetch_tags: true
    clean_tags: true

# 3. Separate read-only and write-only resources
- name: repo-read  # For tracking tags
  type: git
  source:
    <<: *git-source
    tag_regex: "^v.*"
    fetch_tags: true
    clean_tags: true

- name: repo-write  # For pushing tags
  type: git
  source:
    <<: *git-source
    fetch_tags: true
```

**Best Practice**: Treat tags as immutable; avoid force-pushing release branches.

## Additional Resources

### Reference Files

For detailed configuration options, consult:
- **`references/pipeline-syntax.md`** - Complete YAML schema for pipelines, jobs, resources
- **`references/resources-guide.md`** - Git-resource, registry-image-resource configuration
- **`references/best-practices.md`** - Optimization, troubleshooting, security patterns
- **`references/resource-types-catalog.md`** - Available resource types and usage

### Example Files

Working examples in `examples/`:
- **`basic-pipeline.yml`** - Minimal build-test-deploy pattern
- **`multi-branch.yml`** - Dynamic branch pipelines with set_pipeline
- **`docker-build.yml`** - Container image build and push

### Validation Script

Use `scripts/validate-pipeline.sh` to check pipeline syntax before deployment.

## fly CLI Quick Reference

```bash
# Set/update pipeline
fly -t target set-pipeline -p pipeline-name -c pipeline.yml -l vars.yml

# Check resource versions
fly -t target check-resource -r pipeline/resource-name

# Trigger job manually
fly -t target trigger-job -j pipeline/job-name -w

# Hijack into container for debugging
fly -t target hijack -j pipeline/job-name -s step-name

# Watch build logs
fly -t target watch -j pipeline/job-name

# Validate pipeline syntax
fly -t target validate-pipeline -c pipeline.yml
```

## Task Configuration Pattern

Store task configs in repository for version control:

```yaml
# ci/tasks/build.yml
platform: linux
image_resource:
  type: registry-image
  source:
    repository: node
    tag: 20-slim
inputs:
- name: source-repo
outputs:
- name: build-output
caches:
- path: source-repo/node_modules
params:
  NODE_ENV: production
run:
  path: /bin/bash
  args:
  - -exc
  - |
    cd source-repo
    npm ci
    npm run build
    cp -r dist ../build-output/
```

## Pipeline Groups

Organize jobs in the UI without affecting execution:

```yaml
groups:
- name: all
  jobs: ["*"]
- name: build
  jobs: [compile, test]
- name: deploy
  jobs: [deploy-staging, deploy-prod]
- name: infrastructure
  jobs: [terraform-*]  # Glob patterns supported
```
