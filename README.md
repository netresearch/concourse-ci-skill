# Concourse CI Skill

[![Claude Code Compatible](https://img.shields.io/badge/Claude%20Code-Compatible-blue?logo=anthropic)](https://claude.ai)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/netresearch/concourse-ci-skill/releases)

**Agent Skill** for expert Concourse CI pipeline development, optimization, and troubleshooting.

## Supported Platforms

| Platform | Status |
|----------|--------|
| Claude Code (Anthropic) | ✅ Supported |
| Cursor | ✅ Supported |
| GitHub Copilot | ✅ Supported |
| Other skills-compatible AI agents | ✅ Supported |

## Features

- **Pipeline Creation**: Write production-ready Concourse CI pipelines with proper structure
- **Resource Configuration**: Configure git-resource, registry-image-resource, and 50+ resource types
- **Optimization**: Parallel execution, task caching, resource filtering patterns
- **Troubleshooting**: Debug common issues including git tag detection problems
- **Best Practices**: YAML anchors for DRY, job lifecycle hooks, webhook triggers
- **Multi-Branch Pipelines**: Dynamic pipeline management with `set_pipeline` and `across`
- **Container Builds**: OCI image building with `oci-build-task` and versioning

## Installation

### Via Marketplace (Recommended)

```bash
/plugin marketplace add netresearch/claude-code-marketplace
```

### Manual Installation

Download from the [latest release](https://github.com/netresearch/concourse-ci-skill/releases/latest) and extract to:

```bash
~/.claude/skills/concourse-ci-skill/
```

### Via Composer (PHP Projects)

```bash
composer require netresearch/agent-concourse-ci-skill
```

## Usage

The skill activates automatically when you work with Concourse CI topics:

```
"Create a Concourse pipeline for my Node.js app"
"Configure git-resource with tag filtering"
"Debug why my pipeline isn't detecting new tags"
"Optimize my Concourse CI build times"
"Add webhook triggers to my pipeline"
```

## Skill Contents

```
skills/concourse-ci/
├── SKILL.md                          # Core guidance (~1.2k words)
├── references/
│   ├── pipeline-syntax.md            # Complete YAML schema
│   ├── resources-guide.md            # Git, registry-image, time, s3, semver
│   ├── best-practices.md             # Optimization & troubleshooting
│   └── resource-types-catalog.md     # 50+ resource types
├── examples/
│   ├── basic-pipeline.yml            # Build-test-deploy pattern
│   ├── multi-branch.yml              # Dynamic branch pipelines
│   └── docker-build.yml              # OCI image building
└── scripts/
    └── validate-pipeline.sh          # Pipeline validation script
```

## Key Topics Covered

### Pipeline Architecture

- Resources, jobs, steps, and resource types
- Job lifecycle hooks (on_success, on_failure, on_error, on_abort, ensure)
- Step types (get, put, task, set_pipeline, in_parallel, do, try)
- Variable syntax and credential management

### Critical Gotchas

**Git Resource Tag Detection** - The skill documents the notorious issue where Concourse stops detecting tags after force-pushing, including root causes and solutions:

```yaml
# Enable tag cleanup to fix detection issues
resources:
- name: repo
  type: git
  source:
    uri: ((git.uri))
    branch: main
    tag_regex: "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    fetch_tags: true
    clean_tags: true  # Critical fix
```

### Optimization Patterns

- Parallel step execution with `in_parallel`
- Task caching for dependencies
- Shallow clones with `depth: 1`
- Resource path filtering
- Serial groups for resource contention

## Compatibility

- **Concourse v8.0+** (current)
- Legacy support for v6.5+ where noted

## Related Resources

- [Concourse CI Documentation](https://concourse-ci.org/docs/)
- [Concourse GitHub](https://github.com/concourse/concourse)
- [Resource Types Catalog](https://concourse-ci.org/resource-types-list/)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

**Netresearch DTT GmbH**
- Website: [netresearch.de](https://www.netresearch.de/)
- GitHub: [@netresearch](https://github.com/netresearch)
