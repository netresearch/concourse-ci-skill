# Core Concepts Reference

## Step Types

| Step | Purpose |
|------|---------|
| `get` | Fetch resource version |
| `put` | Update/push resource |
| `task` | Execute containerized work |
| `set_pipeline` | Dynamic pipeline config |
| `in_parallel` | Concurrent execution |
| `do` | Sequential execution (all steps in order) |
| `try` | Continue on failure (wraps a step) |
| `load_var` | Load value into a local var from file or literal |

## Job Lifecycle Hooks

| Hook | Triggers When |
|------|---------------|
| `on_success` | Step/job succeeds |
| `on_failure` | Non-zero exit (task failure) |
| `on_error` | Infrastructure error (OOM, timeout) |
| `on_abort` | Build manually aborted |
| `ensure` | Always runs regardless of outcome |

**Important**: `on_failure` (exit code 1) is different from `on_error` (container crash). Handle both.

## Multiple Triggers on One Job

A job with several `get` steps marked `trigger: true` runs when **any one** of
them sees a new version — not only when all of them are simultaneously new.
`deploy-staging` with both `get: app-image-staging, passed: [build-image],
trigger: true` and `get: timer-daily, trigger: true` fires as soon as a build
that satisfies `passed` lands, without waiting for the timer. Do not assume a
manual `trigger-job` or a wait for the slower trigger (a weekly/daily timer) is
needed — check `fly builds -j pipeline/job -c 2` first; the deploy may already
be running.

## fly CLI Essentials

```bash
fly -t target set-pipeline -p pipeline-name -c pipeline.yml -l vars.yml
fly -t target check-resource -r pipeline/resource-name
fly -t target trigger-job -j pipeline/job-name -w
fly -t target hijack -j pipeline/job-name -s step-name
fly -t target validate-pipeline -c pipeline.yml
fly -t target execute -c task.yml -i source=.    # Run task locally
fly -t target execute --include-ignored -c task.yml -i source=.
```

**Scripted/agent usage:** `set-pipeline` prompts `apply configuration? [yN]` and piping
`echo y |` into it does NOT reliably answer the prompt — the call hangs until killed.
Always pass `--non-interactive` in automation, and run `validate-pipeline` first:

```bash
fly -t target validate-pipeline -c pipeline.yml -l vars.yml
fly -t target set-pipeline --non-interactive -p pipeline-name -c pipeline.yml -l vars.yml
```

Verify the applied config afterwards with `fly -t target get-pipeline -p pipeline-name`
(pipe through `yq` to assert the changed key) — "configuration updated" alone does not
show what was applied. Token/team note: fly tokens are user-scoped; a logged-in target
can be cloned to another team by duplicating its `~/.flyrc` entry with a different
`team:` value — no second OAuth login needed.

**Admin (main-team) shortcut:** when the logged-in target belongs to the Concourse
admin team, most commands accept `--team <other-team>` directly — e.g.
`fly -t admin-target set-pipeline --team customer-team -p pipeline …`, same for
`builds`, `trigger-job`, `watch`, `check-resource`. One fresh admin login then covers
every team without cloning `~/.flyrc` entries or chasing per-team OAuth logins.

**Target name ≠ team name:** `-t` names a local `~/.flyrc` entry, not the team.
Makefiles routinely hardcode `fly -t <team>` while the machine's targets are named
differently (`ci-<team>`, an alias, …) — the resulting `error: unknown target` looks
like a login problem but is a naming mismatch. `fly targets` lists what actually
exists, with each entry's team in the third column.

**Verifying builds without CI access:** when no usable fly login exists, the
pipeline's outputs answer most questions. A `put` to a `registry-image` resource
updates the tag's `created_at`/digest (GitLab: `projects/:id/registry/repositories/:rid/tags/<tag>`),
and deploy jobs that push a git tag leave it in `ls-remote --tags`. A stale
`created_at` also dates the last successful build precisely.
