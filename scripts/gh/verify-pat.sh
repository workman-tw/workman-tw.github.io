#!/usr/bin/env bash
#
# verify-pat.sh — Verify GitHub Personal Access Token validity and scopes
#
# DESCRIPTION
#   Reads the PAT from vaults/github/pat.txt and checks:
#   1. Token is valid (can authenticate)
#   2. Token scopes include required permissions
#   3. Token can access the target organization and repository
#
# FILES
#   vaults/github/pat.txt — GitHub Personal Access Token
#
# USAGE
#   ./scripts/gh/verify-pat.sh       # verify PAT
#   just gh-verify                    # run via just command
#
# PREREQUISITES
#   - vaults/github/pat.txt must exist (run 'just decrypt' if encrypted)
#   - curl must be available
#
# EXIT CODES
#   0 — PAT is valid with sufficient scopes
#   1 — PAT file missing, invalid, or insufficient permissions
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PAT_FILE="${ROOT_DIR}/vaults/github/pat.txt"
GH_ORG="workman-tw"
GH_REPO="workman-tw.github.io"

# --- Validate file ---
if [ ! -f "$PAT_FILE" ]; then
  echo "Error: PAT file not found at $PAT_FILE" >&2
  echo "Run: gh auth token > vaults/github/pat.txt" >&2
  exit 1
fi

TOKEN="$(tr -d '[:space:]' < "$PAT_FILE")"

if [ -z "$TOKEN" ]; then
  echo "Error: PAT file is empty." >&2
  exit 1
fi

API="https://api.github.com"
AUTH="Authorization: Bearer ${TOKEN}"
PASS=0
FAIL=0

check() {
  local label="$1"
  local ok="$2"
  if [ "$ok" = "true" ]; then
    echo "  [PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] ${label}"
    FAIL=$((FAIL + 1))
  fi
}

# --- 1. Authentication ---
echo "Checking authentication..."
RESPONSE="$(curl -sf -H "$AUTH" -D - -o /dev/null "${API}/user" 2>/dev/null || echo "HTTP 401")"
SCOPES="$(echo "$RESPONSE" | grep -i '^x-oauth-scopes:' | sed 's/^[^:]*: //' | tr -d '\r')"
USER_INFO="$(curl -sf -H "$AUTH" "${API}/user" 2>/dev/null || echo "{}")"
USERNAME="$(echo "$USER_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))" 2>/dev/null || echo "")"

if [ -n "$USERNAME" ]; then
  echo "  Authenticated as: ${USERNAME}"
  echo "  Scopes: ${SCOPES:-"(fine-grained token — no classic scopes)"}"
  check "Token is valid" "true"
else
  check "Token is valid" "false"
  echo ""
  echo "Token is invalid. Cannot proceed."
  exit 1
fi

# --- 2. Scope check (classic tokens only) ---
echo ""
echo "Checking scopes..."
if [ -n "$SCOPES" ]; then
  echo "$SCOPES" | grep -q "repo" && check "repo scope" "true" || check "repo scope" "false"
  echo "$SCOPES" | grep -q "admin:org" && check "admin:org scope" "true" || check "admin:org scope (needed for environment secrets)" "false"
else
  echo "  (Fine-grained token — scopes verified by API access below)"
fi

# --- 3. Org access ---
echo ""
echo "Checking org access..."
ORG_STATUS="$(curl -sf -o /dev/null -w "%{http_code}" -H "$AUTH" "${API}/orgs/${GH_ORG}" 2>/dev/null || echo "000")"
check "Access to org ${GH_ORG}" "$([ "$ORG_STATUS" = "200" ] && echo true || echo false)"

# --- 4. Repo access ---
echo ""
echo "Checking repo access..."
REPO_STATUS="$(curl -sf -o /dev/null -w "%{http_code}" -H "$AUTH" "${API}/repos/${GH_ORG}/${GH_REPO}" 2>/dev/null || echo "000")"
check "Access to repo ${GH_ORG}/${GH_REPO}" "$([ "$REPO_STATUS" = "200" ] && echo true || echo false)"

# --- 5. Environment secrets access ---
echo ""
echo "Checking environment secrets access..."
ENV_STATUS="$(curl -sf -o /dev/null -w "%{http_code}" -H "$AUTH" "${API}/repos/${GH_ORG}/${GH_REPO}/environments/prod/secrets" 2>/dev/null || echo "000")"
check "Read environment secrets (prod)" "$([ "$ENV_STATUS" = "200" ] && echo true || echo false)"

# --- Summary ---
echo ""
echo "Result: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] || exit 1
