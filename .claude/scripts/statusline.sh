#!/usr/bin/env bash
# Claude Code status line.
#   Line 1: 📁 project · branch · model · effort (when supported)
#   Line 2: context usage (% + tokens, colour-coded) · 5-hour allowance left (%) · reset (clock time)
# Reads session JSON from stdin. Field reference:
#   https://code.claude.com/docs/en/statusline
set -o pipefail

input=$(cat)
jqr() { jq -r "$1" <<<"$input"; }

# --- colours ---------------------------------------------------------------
esc=$'\e'
RESET="${esc}[0m"; DIM="${esc}[2m"; BOLD="${esc}[1m"
CYAN="${esc}[36m"; MAGENTA="${esc}[35m"
GREEN="${esc}[32m"; YELLOW="${esc}[33m"; RED="${esc}[31m"
SEP="${DIM}·${RESET}"

# --- helpers ---------------------------------------------------------------
fmt_k() { # integer tokens -> "56k" / "1.0M"
  local n=${1:-0}
  if [ "$n" -ge 1000000 ]; then awk "BEGIN{printf \"%.1fM\", $n/1000000}"
  else awk "BEGIN{printf \"%dk\", $n/1000}"; fi
}

# --- line 1: project · branch · model --------------------------------------
project_dir=$(jqr '.workspace.project_dir // .cwd // ""')
project=${project_dir##*/}; project=${project:-?}
model=$(jqr '.model.display_name // "?"')

branch=$(git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && branch="—"

# effort.level is absent when the model doesn't support the reasoning param
effort=$(jqr '.effort.level // empty')
effort_seg=""
[ -n "$effort" ] && effort_seg=" $SEP ${DIM}effort:${RESET}${effort}"

printf '%s📁 %s %s %s⎇ %s%s %s %s%s%s%s\n' \
  "$DIM" "$BOLD$project$RESET" \
  "$SEP" "$CYAN" "$branch" "$RESET" \
  "$SEP" "$MAGENTA" "$model" "$RESET" "$effort_seg"

# --- line 2: context usage · allowance left · usage reset -------------------
pct=$(jqr '.context_window.used_percentage // 0' | cut -d. -f1)
used=$(jqr '.context_window.total_input_tokens // 0')
size=$(jqr '.context_window.context_window_size // 200000')

if   [ "$pct" -ge 80 ]; then cc=$RED
elif [ "$pct" -ge 50 ]; then cc=$YELLOW
else cc=$GREEN
fi
ctx=$(printf '%sctx %s%s%s%% (%s/%s)%s' "$DIM" "$RESET" "$cc" "$pct" "$(fmt_k "$used")" "$(fmt_k "$size")" "$RESET")

allowance_seg=""
used_5h=$(jqr '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
if [ -n "$used_5h" ]; then
  left_5h=$((100 - used_5h))
  if   [ "$left_5h" -le 20 ]; then ac=$RED
  elif [ "$left_5h" -le 50 ]; then ac=$YELLOW
  else ac=$GREEN
  fi
  allowance_seg=" $SEP ${DIM}5h ${RESET}${ac}${left_5h}% left${RESET}"
fi

resets_at=$(jqr '.rate_limits.five_hour.resets_at // empty')
if [ -n "$resets_at" ]; then
  reset_time=$(date -d "@$resets_at" +'%-l:%M%P' 2>/dev/null)
  reset_seg=" $SEP ${DIM}resets ${RESET}${reset_time}"
else
  reset_seg=""
fi

printf '%s%s%s\n' "$ctx" "$allowance_seg" "$reset_seg"
