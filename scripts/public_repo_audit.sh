#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

FAIL=0

echo "== Highlander Homes Public Repo Audit =="

echo ""
echo "[1/4] Scanning for AI-builder references..."
BUILDER_HITS="$(python3 - <<'PY'
import re
from pathlib import Path

exclude_prefixes = (
    ".git/",
    "node_modules/",
    "dist/",
    "dev-dist/",
)
terms = re.compile(r"claude code|claude\\b|lovable|emergent|bolt\\.new|bolts?\\.dev|anthropic|made with", re.I)
hits = []

for p in Path(".").rglob("*"):
    if not p.is_file():
        continue
    path = p.as_posix().lstrip("./")
    if path == "scripts/public_repo_audit.sh":
        continue
    if any(path.startswith(prefix) for prefix in exclude_prefixes):
        continue
    try:
        text = p.read_text(errors="ignore")
    except Exception:
        continue
    for i, line in enumerate(text.splitlines(), 1):
        if terms.search(line):
            hits.append(f"{path}:{i}:{line.strip()}")

if hits:
    print("\\n".join(hits))
PY
)"
if [[ -n "$BUILDER_HITS" ]]; then
  echo "$BUILDER_HITS"
  echo "ERROR: Found AI-builder references."
  FAIL=1
else
  echo "OK: No AI-builder references found."
fi

echo ""
echo "[2/4] Scanning tracked files for likely secret leaks..."
SECRET_HITS="$(python3 - <<'PY'
import subprocess, pathlib, re

patterns = [
    ("Stripe live key", re.compile(r"sk_live_[A-Za-z0-9]+")),
    ("AWS access key", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("GitHub token", re.compile(r"ghp_[0-9A-Za-z]{36}")),
    ("Private key block", re.compile(r"-----BEGIN (RSA |EC |OPENSSH |)?PRIVATE KEY-----")),
    ("Hardcoded secret assignment", re.compile(r"(?i)[A-Za-z0-9_]*(API_KEY|SECRET|TOKEN|PASSWORD)[A-Za-z0-9_]*\\s*[:=]\\s*[\\\"\\'][^\\\"\\']{10,}[\\\"\\']")),
]
allowlist = re.compile(
    r"^\\s*#|your_.*_here|placeholder|example",
    re.I,
)
hits = []

for path in subprocess.check_output(["git", "ls-files"], text=True).splitlines():
    p = pathlib.Path(path)
    try:
        text = p.read_text(errors="ignore")
    except Exception:
        continue
    for i, line in enumerate(text.splitlines(), 1):
        lower = line.lower()
        if (
            allowlist.search(line)
            or "process.env." in lower
            or "import.meta.env." in lower
            or "functions.config(" in lower
        ):
            continue
        for label, rx in patterns:
            if rx.search(line):
                hits.append(f"{path}:{i}:{label}")
                break

if hits:
    print("\\n".join(hits))
PY
)"
if [[ -n "$SECRET_HITS" ]]; then
  echo "$SECRET_HITS"
  echo "ERROR: Potential secrets detected in tracked files."
  FAIL=1
else
  echo "OK: No obvious secret values detected in tracked files."
fi

echo ""
echo "[3/4] Verifying environment files are ignored..."
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  echo "ERROR: .env is tracked in git."
  FAIL=1
else
  echo "OK: .env is not tracked."
fi
if git ls-files --error-unmatch .env.local >/dev/null 2>&1; then
  echo "ERROR: .env.local is tracked in git."
  FAIL=1
else
  echo "OK: .env.local is not tracked."
fi

echo ""
echo "[4/4] Optional history check..."
if [[ "${CHECK_HISTORY:-0}" == "1" ]]; then
  HISTORY_HITS="$(python3 - <<'PY'
import subprocess
patterns = r"sk_live_|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|-----BEGIN (RSA |EC |OPENSSH |)?PRIVATE KEY-----"
revs = subprocess.check_output(["git", "rev-list", "--all"], text=True).splitlines()
hits = []
for rev in revs:
    proc = subprocess.run(
        ["git", "grep", "-nE", patterns, rev, "--", ":(exclude)node_modules/*", ":(exclude)dist/*", ":(exclude)dev-dist/*"],
        text=True,
        capture_output=True,
    )
    if proc.returncode == 0 and proc.stdout.strip():
        hits.extend(proc.stdout.strip().splitlines()[:10])
        if len(hits) >= 10:
            break
if hits:
    print("\n".join(hits))
PY
)"
  if [[ -n "$HISTORY_HITS" ]]; then
    echo "$HISTORY_HITS"
    echo "ERROR: Potential leaked secrets found in git history."
    FAIL=1
  else
    echo "OK: No obvious history leaks found by quick pattern scan."
  fi
else
  echo "Skipped. Run with CHECK_HISTORY=1 for history scanning."
fi

echo ""
if [[ "$FAIL" -ne 0 ]]; then
  echo "Audit FAILED."
  exit 1
fi

echo "Audit PASSED."
