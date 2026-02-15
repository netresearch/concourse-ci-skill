---
name: concourse-ci
description: "Use when developing Concourse CI pipelines, configuring resources, troubleshooting builds, or optimizing CI/CD with Concourse v8+."
version: 1.2.0
---

# Concourse CI Pipeline Development

Expert guidance for writing, refactoring, and optimizing Concourse CI pipelines (v8.0+).

## When to Use

- Creating or modifying Concourse pipelines
- Configuring resources (git, registry-image, custom types)
- Building container images with `oci-build-task`
- Troubleshooting resource check failures or build issues
- Migrating from legacy patterns (docker-image, duplicate jobs)

## Quick Reference

| Task | Modern (Recommended) | Legacy (Avoid) |
|------|---------------------|----------------|
| Building images | `oci-build-task` + `registry-image` | `docker-image` resource |
| Multi-env deploys | `across` step modifier | Duplicate jobs per env |
| Dynamic pipelines | `set_pipeline` + instanced pipelines | Manual pipeline duplication |
| Notification symbols | UTF-8 characters | HTML entities |
| Resource styling | Always use `icon:` property | No icon |

### fly CLI Essentials

```bash
fly -t target set-pipeline -p name -c pipeline.yml -l vars.yml
fly -t target check-resource -r pipeline/resource-name
fly -t target trigger-job -j pipeline/job-name -w
fly -t target hijack -j pipeline/job-name -s step-name
fly -t target validate-pipeline -c pipeline.yml
```

## Core Concepts

Pipelines consist of **resources** (external versioned artifacts), **jobs** (sequences of steps), and optional **groups** (UI organization). All execution runs in containers.

### Step Types

| Step | Purpose |
|------|---------|
| `get` | Fetch resource version |
| `put` | Update/push resource |
| `task` | Execute containerized work |
| `set_pipeline` | Dynamic pipeline config |
| `in_parallel` | Concurrent execution |
| `do` / `try` | Sequential / continue-on-failure |

### Job Lifecycle Hooks

| Hook | Triggers When |
|------|---------------|
| `on_success` | Step/job succeeds |
| `on_failure` | Non-zero exit (task failure) |
| `on_error` | Infrastructure error (OOM, timeout) |
| `on_abort` | Build manually aborted |
| `ensure` | Always runs regardless of outcome |

**Important**: `on_failure` (exit code 1) is different from `on_error` (container crash). Handle both.

## Critical Gotchas

1. **Git tag detection after force-push** -- Escape regex dots, enable `clean_tags: true`, separate read/write resources. See `references/resources-guide.md`.
2. **registry_mirror format mismatch** -- `registry-image` expects an object (`host: mirror`), `docker-image` expects a URL string. Provide separate formats in `CONCOURSE_BASE_RESOURCE_TYPE_DEFAULTS`. See `references/resources-guide.md`.
3. **GitLab Container Registry JWT auth** -- The JWT endpoint lives on the GitLab host, not the registry host. Discover via `Www-Authenticate` header. See `references/resources-guide.md`.

## References

- `references/pipeline-syntax.md` -- Complete YAML schema for pipelines, jobs, resources
- `references/resources-guide.md` -- Git-resource, registry-image, docker-image migration, gotcha details
- `references/best-practices.md` -- Optimization, troubleshooting, notifications, deployment patterns
- `references/resource-types-catalog.md` -- Available resource types (Ansible, Terraform, etc.)

### Examples

Working examples in `examples/`:
- `basic-pipeline.yml` -- Build-test-deploy with versioning
- `modern-ci-cd.yml` -- oci-build-task, across, build_log_retention
- `multi-branch.yml` -- Dynamic branch pipelines with set_pipeline
- `docker-build.yml` -- Container image build and push
- `vars-template.yml` -- Variable file organization

### Validation

Use `scripts/validate-pipeline.sh` to check pipeline syntax before deployment.
