<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Security Assurance Case

This document states what users of the Concourse CI skill can and cannot expect in terms of security, and argues why the project meets those expectations. Each claim names the file that implements it. Vulnerabilities are reported privately as described in the organisation's [security policy](https://github.com/netresearch/.github/blob/main/SECURITY.md).

## What the project ships

| Component | Path | Runs code? |
|-----------|------|------------|
| Skill definition | `skills/concourse-ci/SKILL.md` | No. An AI agent reads it as instructions. |
| References | `skills/concourse-ci/references/*.md` | No. Documentation the agent consults. |
| Example pipelines | `skills/concourse-ci/examples/*.yml` | No. Starting points users copy into their own projects. |
| Checkpoints | `skills/concourse-ci/checkpoints.yaml` | Only when an assessment tool runs its `pattern` commands against a user's project. |
| Pipeline validator | `skills/concourse-ci/scripts/validate-pipeline.sh` | Yes, on the user's machine, with the user's privileges. |
| Development scripts | `Build/`, `scripts/`, `tests/` | Yes, for maintainers only. The npm package does not contain them (`files` in `package.json`); Composer and git installs contain the whole repository. |

## Actors and data flow

1. A user installs the skill (marketplace, git clone, npm, Composer or a release archive; see `README.md`).
2. The user's AI agent loads `SKILL.md` when a request matches its description and reads references and examples as needed.
3. The agent writes or changes pipeline YAML in the user's project. `SKILL.md` allows the agent the tools `Bash(fly:*)`, `Bash(yq:*)`, `Read`, `Write`, `Glob` and `Grep`; the agent runtime decides whether the user must approve each call.
4. The agent or the user may run `validate-pipeline.sh <pipeline.yml> [vars.yml...]`. The script reads the pipeline file, runs `yq`, `grep`, `head`, `awk` and `tr` on it, and, if `fly` is installed, runs `fly targets` and `fly validate-pipeline`. It prints its findings and exits 1 if it found an error. It writes no files.

## Trust boundaries

- **Skill content to agent.** The project controls the text the agent reads; it does not control what the agent does with it. Everything the agent produces from the skill is untrusted until a human reviews it.
- **Pipeline file to validator.** The pipeline file is input data. The validator passes its path to `yq`, `grep`, `fly` and the `python3` syntax check as a separate quoted argument (`validate-pipeline.sh`, `fly_args` array), never through `eval` or program text, and runs under `set -euo pipefail`. Resource names read from the file reach `yq` through the environment (`strenv`), never as part of a `yq` expression, and are printed with `printf '%s'`, so a backslash sequence in a name is shown as text.
- **Validator to Concourse.** When `fly` is installed and a target is logged in, the validator passes the first target that `fly targets` lists to `fly validate-pipeline`. It never runs `fly login`, `fly set-pipeline` or any other command that changes a Concourse installation.
- **Contributions to the repository.** The branch protection of `main` requires a pull request for every account except repository administrators; the checks listed below run on each pull request to `main`.

## Security requirements and how they are met

| Requirement | How it is met | Evidence |
|-------------|---------------|----------|
| Skill content never recommends literal credentials in pipelines. | The references and examples use `((var))` placeholders and `var_sources` credential managers. | `references/best-practices.md` (section "Credential Management"), `references/pipeline-syntax.md`, `examples/vars-template.yml` |
| Literal credentials in a pipeline are reported (CWE-798). | The validator warns on `password:`, `secret:`, `token:` or `key:` followed by a literal value when the file contains no `((` placeholder. Checkpoint CC-08 reports a literal `password:`, `secret:` or `token:` value in an assessed project's pipeline files. | `validate-pipeline.sh` (`validate_common_issues`), `checkpoints.yaml`, `tests/validate-pipeline.sh` cases "literal credential is reported" and "((variable)) credential is not reported" |
| The validator does not execute pipeline content (CWE-78). | File paths are passed as arguments; the validator writes nothing and changes no Concourse state. | `validate-pipeline.sh`, `tests/validate-pipeline.sh` (the fly stub records the exact arguments) |
| A failed validation is visible to callers. | The validator exits 1 when it records an error. A missing file, invalid YAML or a missing `yq` ends the run at once with exit 1 and no summary; any other error is reported after a summary with error and warning counts. | `validate-pipeline.sh` (`main`), `tests/validate-pipeline.sh` |
| The repository holds no secrets. | Betterleaks scans every push to `main` and every pull request to `main`. | `.github/workflows/security.yml` |
| CI cannot be steered by pull request content (CWE-94). | Workflows start with `permissions: {}` and grant each job only the scopes its reusable workflow needs. No workflow in this repository has a `run:` step that expands event data. The two `pull_request_target` workflows only call reusables that label or merge and do not check out pull request code. zizmor analyses the workflows. | `.github/workflows/*.yml`, `security.yml` (zizmor job) |
| Dependencies and code are scanned (OWASP A06:2021). | Composer Audit, dependency review and Opengrep run on pull requests; Renovate proposes updates, including for pre-commit hooks. | `security.yml`, `renovate.json` |
| Releases can be verified. | Releases run only from tags. The release reusable checks that the tag is annotated and signed, publishes `SHA256SUMS.txt` signed with Cosign (keyless) and attests build provenance for the archives. | `.github/workflows/release.yml`, [skill-repo-skill `release.yml`](https://github.com/netresearch/skill-repo-skill/blob/main/.github/workflows/release.yml) |

## Secure design principles applied

- **Least privilege.** Workflow tokens are scoped per job (`permissions: {}` at the top of every workflow). The only shell commands `SKILL.md` lists in `allowed-tools` are `fly` and `yq`.
- **Fail safe.** The validator runs with `set -euo pipefail` and exits non-zero on any error; missing input files and invalid YAML end the run with exit 1.
- **Economy of mechanism.** The validator is one Bash script with no dependencies beyond `yq`, standard text tools and optionally `fly`.
- **Complete mediation in CI.** Every pull request to `main` runs the same checks; none can be skipped by a path filter.

## Checks on every pull request to `main`

`security.yml` (Betterleaks, zizmor, dependency review, Composer Audit, Opengrep, CodeQL for GitHub Actions), `lint.yml` (skill validation including ShellCheck, markdownlint, yamllint, actionlint), `tests.yml` (behaviour tests), `eval-validate.yml`, `harness-verify.yml` and `check-template-drift.yml`.

## What users cannot expect

- The skill does not make an agent's output safe. Review generated pipelines before running `fly set-pipeline`.
- `validate-pipeline.sh` is a heuristic checker, not a security scanner. The credential check is a pattern match and misses secrets that do not follow the `key: value` form. The script needs `yq`; without it, it stops after reporting that `yq` is missing.
- The example pipelines are templates. Their `((var))` placeholders, image references and resource settings must be adapted and reviewed.
- The checkpoints in `checkpoints.yaml` run shell commands in the assessed project when an assessment tool executes them; run them only in projects you trust.
- Security fixes follow the supported-versions rules of the organisation's security policy; older releases may not receive them.
