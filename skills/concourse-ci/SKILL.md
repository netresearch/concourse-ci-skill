---
name: concourse-ci
description: "Use when working with ANY Concourse CI task: writing pipelines, configuring resources, building images with oci-build-task, troubleshooting failing jobs, migrating from legacy patterns, or optimizing CI/CD. Triggers on: Concourse, pipeline, fly CLI, resource type, oci-build-task, set_pipeline, concourse.yml."
license: "(MIT AND CC-BY-SA-4.0)"
compatibility: "Requires fly CLI, yq."
metadata:
  version: "1.4.0"
  repository: "https://github.com/netresearch/concourse-ci-skill"
  author: "Netresearch DTT GmbH"
allowed-tools:
  - "Bash(fly:*)"
  - "Bash(yq:*)"
  - "Read"
  - "Write"
  - "Glob"
  - "Grep"
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
| Notification symbols | UTF-8 characters (e.g. `\u2714` for checkmark, `\u274c` for X) | HTML entities (e.g. `&check;`, `&cross;`) |
| Resource styling | Always use `icon:` property | No icon |

## Core Concepts

Pipelines consist of **resources** (external versioned artifacts), **jobs** (sequences of steps), and optional **groups** (UI organization). All execution runs in containers.

Key step types: `get`, `put`, `task`, `set_pipeline`, `in_parallel`, `do`, `try`, `load_var`. Job hooks: `on_success`, `on_failure`, `on_error`, `on_abort`, `ensure`. Note: `on_failure` (exit code 1) differs from `on_error` (container crash) -- handle both.

See `references/core-concepts.md` for step types table, lifecycle hooks, and fly CLI essentials.

## Critical Gotchas

1. **Git tag detection after force-push** -- Escape regex dots, enable `clean_tags: true`, separate read/write resources. See `references/resources-guide.md`.
2. **registry_mirror format mismatch** -- `registry-image` expects an object (`host: mirror`), `docker-image` expects a URL string. Provide separate formats in `CONCOURSE_BASE_RESOURCE_TYPE_DEFAULTS`. See `references/resources-guide.md`.
3. **GitLab Container Registry JWT auth** -- The JWT endpoint lives on the GitLab host, not the registry host. Discover via `Www-Authenticate` header. See `references/resources-guide.md`.

## References

- `references/pipeline-syntax.md` -- Complete YAML schema for pipelines, jobs, resources
- `references/core-concepts.md` -- Step types, lifecycle hooks, fly CLI essentials
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
