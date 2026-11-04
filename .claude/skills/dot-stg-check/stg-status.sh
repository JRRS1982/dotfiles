#!/usr/bin/env bash
# Report whether a pull request's head commit was deployed to staging and had
# its acceptance tests run, from the CI statuses GitHub holds for its commits
# and the CircleCI config at that commit.
#
# Usage: bash stg-status.sh [PR-number]
#   With no argument, uses the PR for the current branch, or, without one,
#   the branch's own commits since it left origin/main (or origin/master).
#
# Prints exactly two lines, `Staging: ...` and `Acceptance tests...`.
# A line that asks the author to act starts with `Warning — `.
# Read-only: every call is a GET.

set -euo pipefail

readonly MAX_COMMITS=10
readonly ACCEPTANCE_RE='acceptance|e2e|bs-tests'
readonly STAGING_RE='stg|staging'
readonly NOT_A_DEPLOY_RE='^build|k6'
readonly GATE_NAME_RE='approval|kick-off'

pr="${1:-}"

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Commits oldest-first, head last.
commits=()
if pr_commits="$(gh pr view ${pr:+"$pr"} --json commits -q '.commits[].oid' 2>/dev/null)" && [ -n "$pr_commits" ]; then
  mapfile -t commits <<<"$pr_commits"
else
  base=""
  for candidate in origin/main origin/master; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null; then base="$candidate"; break; fi
  done
  if [ -z "$base" ]; then
    echo "Staging: unknown — no PR and no origin/main or origin/master to compare against."
    echo "Acceptance tests: unknown — see the Staging line."
    exit 0
  fi
  mapfile -t commits < <(git rev-list --reverse "$(git merge-base "$base" HEAD)..HEAD")
  # Already on the base (a merged branch, a detached snapshot): HEAD alone.
  [ "${#commits[@]}" -eq 0 ] && commits=("$(git rev-parse HEAD)")
fi

head_sha="${commits[-1]}"
short() { printf '%s' "${1:0:8}"; }
comma_list() { paste -sd',' | sed 's/,/, /g'; }

# gh prints the error body to stdout on a 404, so discard output on failure.
circleci_config="$(
  gh api -H 'Accept: application/vnd.github.raw' \
    "repos/$repo/contents/.circleci/config.yml?ref=$head_sha" 2>/dev/null
)" || circleci_config=""

# Workflow jobs in that config, one per line: name, type, requires (comma-separated).
config_jobs="$(
  printf '%s' "$circleci_config" |
    yq -r 'explode(.) | .workflows[] | select(type == "!!map") | .jobs[]?
           | select(type == "!!map") | to_entries[]
           | [(.value.name // .key), (.value.type // "job"),
              ((.value.requires // []) | join(","))] | @tsv' 2>/dev/null
)" || config_jobs=""

# Approval gates. A matrix name such as `deploy-stg-<< matrix.variant >>`
# becomes a pattern. Names containing `approval` or `kick-off` count as gates
# even when the config cannot be read.
config_gates="$(
  awk -F'\t' '$2 == "approval" {print $1}' <<<"$config_jobs" | sort -u |
    sed -E 's/<<[^>]*>>/[^ ]*/g' | paste -sd'|' || true
)"
gate_re="$GATE_NAME_RE"
[ -n "$config_gates" ] && gate_re="^($config_gates)\$|$GATE_NAME_RE"

# One line per CI status: kind, job, state, updated_at, url.
# kind is one of: staging-gate, acceptance-gate, staging, acceptance.
classified_statuses() {
  gh api "repos/$repo/commits/$1/status?per_page=100" \
    --jq '.statuses[] | [.context, .state, .updated_at, (.target_url // "")] | @tsv' 2>/dev/null |
    awk -F'\t' -v OFS='\t' -v gate="$gate_re" -v acc="$ACCEPTANCE_RE" \
      -v stg="$STAGING_RE" -v nodeploy="$NOT_A_DEPLOY_RE" '
      {
        job = $1; sub(/^ci\/circleci: /, "", job)
        if (job ~ gate) {
          if (job ~ acc) kind = "acceptance-gate"
          else if (job ~ stg) kind = "staging-gate"
          else next
        } else if (job ~ acc) kind = "acceptance"
        else if (job ~ stg && job !~ nodeploy) kind = "staging"
        else next
        print kind, job, $2, $3, $4
      }' || true
}

rows_of() { awk -F'\t' -v k="$2" '$1 == k' <<<"$1"; }

# passed | failed | running | none, for a set of rows.
overall() {
  local rows="$1"
  [ -z "$rows" ] && { echo none; return; }
  if grep -qP '\t(failure|error)\t' <<<"$rows"; then echo failed
  elif grep -qP '\tpending\t' <<<"$rows"; then echo running
  else echo passed
  fi
}

jobs_with_state() { awk -F'\t' -v s="$2" '$3 ~ s {print $2}' <<<"$1" | comma_list; }
stamp() { cut -f4 <<<"$1" | sort | tail -1 | sed -E 's/T([0-9]{2}:[0-9]{2}).*/ \1 UTC/'; }
first_url() { cut -f5 <<<"$1" | grep -m1 . || true; }
pending_gates() { awk -F'\t' '$3 == "pending" {print $2}' <<<"$1" | head -3 | comma_list; }

# The newest earlier commit on which <kind> passed, as "sha behind".
last_pass_before_head() {
  local kind="$1" i rows
  local stop=$(( ${#commits[@]} - 1 - MAX_COMMITS ))
  (( stop < 0 )) && stop=0
  for (( i = ${#commits[@]} - 2; i >= stop; i-- )); do
    rows="$(rows_of "$(classified_statuses "${commits[$i]}")" "$kind")"
    if [ "$(overall "$rows")" = passed ]; then
      echo "${commits[$i]} $(( ${#commits[@]} - 1 - i ))"
      return
    fi
  done
}

behind_warning() {
  local label="$1" done_word="$2" older="$3" url="$4" old_sha behind
  read -r old_sha behind <<<"$older"
  echo "Warning — $label: last $done_word on $(short "$old_sha"), $behind commit(s) behind head; re-run it on the latest code before merging.${url:+ $url}"
}

# The line for one kind of job, judged by status names alone.
report_by_status() {
  local label="$1" kind="$2" done_word="$3" not_done="$4" none_offered="$5" head_rows="$6"
  local runs gates url older
  runs="$(rows_of "$head_rows" "$kind")"
  gates="$(rows_of "$head_rows" "$kind-gate")"
  url="$(first_url "${runs:-$gates}")"

  case "$(overall "$runs")" in
    passed)
      echo "$label: $done_word on head $(short "$head_sha") — $(cut -f2 <<<"$runs" | comma_list) ($(stamp "$runs"))."
      return ;;
    failed)
      echo "Warning — $label: failed on head $(short "$head_sha") — $(jobs_with_state "$runs" 'failure|error'). Fix and re-run before merging.${url:+ $url}"
      return ;;
    running)
      echo "$label: running on head $(short "$head_sha") — $(jobs_with_state "$runs" pending)."
      return ;;
  esac

  older="$(last_pass_before_head "$kind")"
  if [ -n "$older" ]; then
    behind_warning "$label" "$done_word" "$older" "$url"
  elif [ -n "$gates" ]; then
    echo "Warning — $label: $not_done on head $(short "$head_sha") — approve $(pending_gates "$gates") in CircleCI before merging.${url:+ $url}"
  else
    echo "$label: $none_offered"
  fi
}

# Short suite name: blue-staging-run-acceptance-tests-chrome -> chrome.
suite() { sed -E 's/^.*staging-run-//; s/acceptance-tests-?//; s/-$//'; }

# Acceptance jobs in the config: name, then its gates (comma-separated).
# With a deploy list, only the jobs that require one of those deploys, which
# are the jobs that test this branch rather than shared staging.
acceptance_jobs() {
  awk -F'\t' -v OFS='\t' -v acc="$ACCEPTANCE_RE" -v gate="$gate_re" -v deployed="${1:-}" '
    BEGIN { n = split(deployed, d, ",") }
    $2 == "job" && $1 ~ acc && $1 !~ gate {
      hit = (n == 0); gates = ""
      m = split($3, req, ",")
      for (i = 1; i <= m; i++) {
        if (req[i] ~ gate) { gates = gates (gates ? "," : "") req[i]; continue }
        pat = req[i]; gsub(/<<[^>]*>>/, "[^,]*", pat)
        for (j = 1; j <= n; j++) if (d[j] ~ ("^" pat "$")) hit = 1
      }
      if (hit && !seen[$1]++) print $1, gates
    }' <<<"$config_jobs"
}

# The acceptance line, suite by suite, against the deploys that passed on head.
report_acceptance() {
  local head_rows="$1" deploys jobs job job_gates state url older
  local passed=() failed=() running=() not_run=() gates_needed=() g=()

  if [ -z "$(acceptance_jobs)" ]; then
    echo "Acceptance tests: none in this repository's pipeline."
    return
  fi

  deploys="$(awk -F'\t' '$1 == "staging" && $3 == "success" {print $2}' <<<"$head_rows" | paste -sd',')"
  jobs=""
  [ -n "$deploys" ] && jobs="$(acceptance_jobs "$deploys")"
  url="$(first_url "$(rows_of "$head_rows" acceptance)$(rows_of "$head_rows" acceptance-gate)")"

  if [ -z "$jobs" ]; then
    older="$(last_pass_before_head acceptance)"
    if [ -n "$older" ]; then
      behind_warning "Acceptance tests" passed "$older" "$url"
    elif [ -z "$deploys" ] && [ "$(overall "$(rows_of "$head_rows" staging)")" = running ]; then
      echo "Acceptance tests: waiting for the staging deploy on head $(short "$head_sha") to finish."
    elif [ -z "$deploys" ]; then
      echo "Warning — Acceptance tests: not run — staging is not deployed on head $(short "$head_sha"); deploy it, then run: $(acceptance_jobs | cut -f1 | suite | sort -u | comma_list)."
    else
      echo "Acceptance tests: none in this pipeline test $(tr ',' '\n' <<<"$deploys" | comma_list)."
    fi
    return
  fi

  while IFS=$'\t' read -r job job_gates; do
    state="$(awk -F'\t' -v j="$job" '$1 == "acceptance" && $2 == j {print $3; exit}' <<<"$head_rows")"
    case "$state" in
      success) passed+=("$(suite <<<"$job")") ;;
      failure|error) failed+=("$(suite <<<"$job")") ;;
      pending) running+=("$(suite <<<"$job")") ;;
      *)
        not_run+=("$(suite <<<"$job")")
        IFS=',' read -ra g <<<"$job_gates"
        gates_needed+=("${g[@]}") ;;
    esac
  done <<<"$jobs"

  local total=$(( ${#passed[@]} + ${#failed[@]} + ${#running[@]} + ${#not_run[@]} ))
  local target
  target="against $(tr ',' '\n' <<<"$deploys" | comma_list) on head $(short "$head_sha")"

  if (( ${#passed[@]} == total )); then
    echo "Acceptance tests: all $total passed $target — $(printf '%s\n' "${passed[@]}" | comma_list)."
    return
  fi

  local parts=()
  (( ${#passed[@]} )) && parts+=("passed: $(printf '%s\n' "${passed[@]}" | comma_list)")
  (( ${#failed[@]} )) && parts+=("failed: $(printf '%s\n' "${failed[@]}" | comma_list)")
  (( ${#running[@]} )) && parts+=("running: $(printf '%s\n' "${running[@]}" | comma_list)")
  if (( ${#not_run[@]} )); then
    local approve=""
    (( ${#gates_needed[@]} )) && approve=" (approve $(printf '%s\n' "${gates_needed[@]}" | sort -u | comma_list))"
    parts+=("not run: $(printf '%s\n' "${not_run[@]}" | comma_list)$approve")
  fi
  local summary
  summary="$(printf '%s\n' "${parts[@]}" | paste -sd';' | sed 's/;/; /g')"

  if (( ${#failed[@]} + ${#not_run[@]} )); then
    echo "Warning — Acceptance tests: ${#passed[@]}/$total passed $target — $summary. Cover the rest before merging.${url:+ $url}"
  else
    echo "Acceptance tests: ${#passed[@]}/$total passed $target — $summary."
  fi
}

if [ -z "$(gh api "repos/$repo/commits/$head_sha/status" --jq '.statuses[0].context // empty' 2>/dev/null || true)" ]; then
  if [ -z "$circleci_config" ]; then
    echo "Staging: none — this repository has no CircleCI pipeline."
    echo "Acceptance tests: none — this repository has no CircleCI pipeline."
    exit 0
  fi
  echo "Staging: unknown — no CI statuses on head $(short "$head_sha"); is the branch pushed and CI running?"
  echo "Acceptance tests: unknown — see the Staging line."
  exit 0
fi

head_rows="$(classified_statuses "$head_sha")"

report_by_status "Staging" staging deployed "not deployed" \
  "no staging deploy in this branch's pipeline." "$head_rows"

if [ -n "$config_jobs" ]; then
  report_acceptance "$head_rows"
else
  report_by_status "Acceptance tests" acceptance passed "not run" \
    "none in this branch's pipeline." "$head_rows"
fi
