#!/bin/zsh
set -euo pipefail

trap 'echo; echo "❌ Script failed at line $LINENO (exit $?)"; read -k1 "?Press any key to close..."' ERR

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_DIR"

if [[ ! -x "./venv/bin/hermes" ]]; then
  echo "Hermes venv not found at: $REPO_DIR/venv"
  echo "Run: ./setup-hermes.sh"
  read -k1 "?Press any key to close..."
  echo
  exit 1
fi

missing="$(
./venv/bin/python - <<'PY'
from pathlib import Path
import os
import yaml

cfg = Path.home() / ".hermes" / "config.yaml"
envp = Path.home() / ".hermes" / ".env"

def parse_env(path: Path):
    data = {}
    if not path.exists():
        return data
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, v = s.split("=", 1)
        data[k.strip()] = v.strip()
    return data

env = parse_env(envp)
cfg_data = {}
if cfg.exists():
    try:
        cfg_data = yaml.safe_load(cfg.read_text(encoding="utf-8")) or {}
    except Exception:
        cfg_data = {}

platforms = cfg_data.get("platforms", {})
feishu_enabled = bool((platforms.get("feishu") or {}).get("enabled"))
weixin_enabled = bool((platforms.get("weixin") or {}).get("enabled"))

missing = []
if feishu_enabled:
    if not env.get("FEISHU_APP_ID"):
        missing.append("FEISHU_APP_ID")
    if not env.get("FEISHU_APP_SECRET"):
        missing.append("FEISHU_APP_SECRET")
if weixin_enabled:
    if not env.get("WEIXIN_ACCOUNT_ID"):
        missing.append("WEIXIN_ACCOUNT_ID")
    if not env.get("WEIXIN_TOKEN"):
        missing.append("WEIXIN_TOKEN")

print(",".join(missing))
PY
)"

if [[ -n "${missing}" ]]; then
  echo "Gateway credentials are incomplete: ${missing}"
  echo "Opening gateway setup wizard..."
  ./venv/bin/hermes setup gateway
fi

LOG_DIR="$HOME/.hermes"
LOG_FILE="$LOG_DIR/gateway.log"
mkdir -p "$LOG_DIR"

echo "Starting hermes gateway... (close window to stop)"
echo "Log: $LOG_FILE"
echo "----------------------------------------"
./venv/bin/hermes gateway run --replace 2>&1 | tee "$LOG_FILE"
