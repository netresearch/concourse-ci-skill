# Architecture — Concourse CI Skill

## Purpose

The Concourse CI Skill provides AI agents with expert knowledge for writing, optimizing, and troubleshooting Concourse CI pipelines. It packages reference documentation, example pipelines, and validation scripts into a portable skill format.

## Component Map

```
┌──────────────────────────────────────────────┐
│  SKILL.md (entry point)                      │
│  Triggers: Concourse, pipeline, fly CLI,     │
│  resource type, oci-build-task               │
└──────────┬───────────────────────────────────┘
           │
    ┌──────┼──────────┬──────────────┐
    ▼      ▼          ▼              ▼
References  Examples  Scripts     Checkpoints
    │         │         │
    ▼         ▼         ▼
5 docs    5 YAML    validate-
(syntax,  pipeline  pipeline.sh
resources,examples
practices)
```

## Key Components

### References (`skills/concourse-ci/references/`)
Comprehensive documentation covering:
- **pipeline-syntax.md** — Complete YAML schema for pipelines, jobs, resources, steps
- **core-concepts.md** — Step types table, lifecycle hooks (on_success/failure/error/abort/ensure), fly CLI essentials
- **resources-guide.md** — Git-resource configuration, registry-image, docker-image migration, critical gotchas (tag detection, registry mirrors, GitLab JWT auth)
- **best-practices.md** — Optimization patterns (parallel execution, caching, shallow clones), notification setup, deployment strategies
- **resource-types-catalog.md** — 50+ community resource types (Ansible, Terraform, Slack, etc.)

### Examples (`skills/concourse-ci/examples/`)
Ready-to-use pipeline YAML files demonstrating common patterns: basic CI/CD, modern patterns with `across`, multi-branch with `set_pipeline`, OCI image builds, and variable file organization.

### Scripts (`skills/concourse-ci/scripts/`)
- **validate-pipeline.sh** — Validates pipeline YAML structure using `fly` CLI or `yq` fallback

## Integration Points

- **AI Agent** — Reads SKILL.md, consults references and examples to generate pipeline YAML
- **fly CLI** — Pipeline validation and deployment
- **yq** — YAML processing and validation fallback
- **Composer** — Installable as a PHP package via `netresearch/composer-agent-skill-plugin`

## Data Flow

1. Agent receives request about Concourse CI pipelines
2. SKILL.md activates, provides quick reference and gotchas
3. Agent consults detailed references for syntax/patterns
4. Agent uses examples as templates for new pipelines
5. validate-pipeline.sh verifies generated YAML
