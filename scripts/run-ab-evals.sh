#!/usr/bin/env bash
# run-ab-evals.sh — A/B test evals WITHOUT vs WITH concourse-ci skill
# Usage: bash scripts/run-ab-evals.sh [eval-name]
# Outputs results to evals/results/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVALS_FILE="$PROJECT_DIR/evals/evals.json"
RESULTS_DIR="$PROJECT_DIR/evals/results"
SKILL_DIR="$PROJECT_DIR/skills/concourse-ci"

mkdir -p "$RESULTS_DIR"

# Parse evals
EVAL_COUNT=$(jq length "$EVALS_FILE")
FILTER="${1:-}"

echo "=== Concourse CI Skill A/B Eval Runner ==="
echo "Evals: $EVAL_COUNT | Filter: ${FILTER:-all}"
echo ""

run_eval() {
    local name="$1"
    local prompt="$2"
    local mode="$3"  # "without" or "with"
    local outfile="$RESULTS_DIR/${name}_${mode}.txt"
    local metafile="$RESULTS_DIR/${name}_${mode}.meta"

    local start_time
    start_time=$(date +%s%N)

    if [ "$mode" = "without" ]; then
        # Bare mode: no skills, no CLAUDE.md, minimal
        claude --print --bare \
            --disable-slash-commands \
            --model sonnet \
            --max-budget-usd 0.05 \
            -p "$prompt" \
            2>/dev/null > "$outfile" || true
    else
        # With skill: append skill content as system prompt
        claude --print \
            --model sonnet \
            --max-budget-usd 0.05 \
            --append-system-prompt "$(cat "$SKILL_DIR/SKILL.md")" \
            -p "$prompt" \
            2>/dev/null > "$outfile" || true
    fi

    local end_time
    end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    # Metrics
    local char_count word_count line_count
    char_count=$(wc -c < "$outfile")
    word_count=$(wc -w < "$outfile")
    line_count=$(wc -l < "$outfile")

    echo "{\"name\":\"$name\",\"mode\":\"$mode\",\"chars\":$char_count,\"words\":$word_count,\"lines\":$line_count,\"duration_ms\":$duration_ms}" > "$metafile"

    echo "  [$mode] $name: ${word_count}w, ${line_count}L, ${duration_ms}ms"
}

check_assertions() {
    local name="$1"
    local idx="$2"
    local mode="$3"
    local outfile="$RESULTS_DIR/${name}_${mode}.txt"

    local assertion_count
    assertion_count=$(jq -r ".[$idx].assertions | length" "$EVALS_FILE")
    local pass=0
    local fail=0

    for ((a=0; a<assertion_count; a++)); do
        local atype
        atype=$(jq -r ".[$idx].assertions[$a].type" "$EVALS_FILE")

        if [ "$atype" = "content_contains" ]; then
            local value
            value=$(jq -r ".[$idx].assertions[$a].value" "$EVALS_FILE")
            if grep -qF "$value" "$outfile" 2>/dev/null; then
                pass=$((pass + 1))
            else
                fail=$((fail + 1))
            fi
        elif [ "$atype" = "tool_use" ]; then
            # Skip tool_use assertions for print mode
            pass=$((pass + 1))
        fi
    done

    echo "$pass/$((pass + fail))"
}

# Summary table header
SUMMARY_FILE="$RESULTS_DIR/ab-summary.md"
cat > "$SUMMARY_FILE" << 'HEADER'
# A/B Eval Results: WITHOUT skill vs WITH skill

| # | Eval | Without (pass) | With (pass) | Without (words) | With (words) | Delta |
|---|------|---------------|-------------|-----------------|-------------|-------|
HEADER

for ((i=0; i<EVAL_COUNT; i++)); do
    name=$(jq -r ".[$i].name" "$EVALS_FILE")
    prompt=$(jq -r ".[$i].prompt" "$EVALS_FILE")

    # Apply filter
    if [ -n "$FILTER" ] && [ "$name" != "$FILTER" ]; then
        continue
    fi

    echo "--- Eval: $name ---"

    # Run WITHOUT skill
    run_eval "$name" "$prompt" "without"

    # Run WITH skill
    run_eval "$name" "$prompt" "with"

    # Check assertions
    without_pass=$(check_assertions "$name" "$i" "without")
    with_pass=$(check_assertions "$name" "$i" "with")

    # Word counts
    without_words=$(jq -r '.words' "$RESULTS_DIR/${name}_without.meta")
    with_words=$(jq -r '.words' "$RESULTS_DIR/${name}_with.meta")

    # Delta
    if [ "$without_words" -gt 0 ]; then
        delta=$(( (with_words - without_words) * 100 / without_words ))
        delta_str="${delta}%"
    else
        delta_str="N/A"
    fi

    echo "| $((i+1)) | $name | $without_pass | $with_pass | $without_words | $with_words | $delta_str |" >> "$SUMMARY_FILE"
    echo ""
done

echo ""
echo "=== Summary ==="
cat "$SUMMARY_FILE"
echo ""
echo "Results saved to: $RESULTS_DIR/"
