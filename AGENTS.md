# Concourse CI Skill — Agent Index

## Repo Structure

```
├── skills/concourse-ci/           # Skill definition and content
│   ├── SKILL.md                   # Skill metadata, triggers, quick reference
│   ├── checkpoints.yaml           # Skill checkpoints
│   ├── references/                # Detailed reference documentation
│   │   ├── pipeline-syntax.md     # Complete YAML schema
│   │   ├── core-concepts.md       # Step types, hooks, fly CLI
│   │   ├── resources-guide.md     # Git, registry-image, docker-image migration
│   │   ├── best-practices.md      # Optimization, notifications, deployment
│   │   └── resource-types-catalog.md # 50+ resource types
│   ├── examples/                  # Example pipeline YAML files
│   │   ├── basic-pipeline.yml
│   │   ├── modern-ci-cd.yml
│   │   ├── multi-branch.yml
│   │   ├── docker-build.yml
│   │   └── vars-template.yml
│   └── scripts/
│       └── validate-pipeline.sh   # Pipeline validation script
├── evals/                         # Skill evaluation tests
├── .github/workflows/             # CI: lint, release, auto-merge-deps, harness-verify
├── composer.json                  # Composer package (ai-agent-skill type)
├── docs/                          # Architecture and execution plans
│   └── ARCHITECTURE.md
└── scripts/                       # Repo-level scripts (verify-harness.sh)
```

## Commands

No Makefile or npm scripts. Key commands:

- `skills/concourse-ci/scripts/validate-pipeline.sh <file>` — validate a Concourse pipeline YAML
- `bash scripts/verify-harness.sh --format=text --status` — verify harness maturity

## Rules

- Target Concourse v8.0+ (legacy support for v6.5+ where noted)
- Use `oci-build-task` + `registry-image` instead of legacy `docker-image` resource
- Use `across` step modifier instead of duplicating jobs per environment
- Use `set_pipeline` for dynamic/multi-branch pipelines
- Use UTF-8 characters for notification symbols, not HTML entities
- Always set `icon:` property on resources
- Git tag detection: escape regex dots, enable `clean_tags: true`, use separate read/write resources
- Split license: MIT for code, CC-BY-SA-4.0 for content

## References

- [skills/concourse-ci/SKILL.md](skills/concourse-ci/SKILL.md) — skill definition, triggers, quick reference
- [skills/concourse-ci/references/](skills/concourse-ci/references/) — pipeline syntax, resources, best practices
- [skills/concourse-ci/examples/](skills/concourse-ci/examples/) — example pipeline YAML files
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — architecture overview
- [README.md](README.md) — installation and usage guide
