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

## fly CLI Essentials

```bash
fly -t target set-pipeline -p pipeline-name -c pipeline.yml -l vars.yml
fly -t target check-resource -r pipeline/resource-name
fly -t target trigger-job -j pipeline/job-name -w
fly -t target hijack -j pipeline/job-name -s step-name
fly -t target validate-pipeline -c pipeline.yml
```
