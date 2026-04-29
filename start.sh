#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NanoClaw startup script for Railway
# ─────────────────────────────────────────────────────────────────────────────
set -e

CONFIG_DIR="/data/.zeroclaw"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
WORKSPACE="/data/workspace"

echo "🦀 NanoClaw starting up..."

# ── 1. Create directory layout on first boot ─────────────────────────────────
mkdir -p "${CONFIG_DIR}" "${WORKSPACE}"

# ── 2. Write switch-model.sh helper (always overwrite — keep it fresh) ───────
cat > "${WORKSPACE}/switch-model.sh" << 'SWITCHSCRIPT'
#!/usr/bin/env bash
# switch-model.sh  <provider>  <model>
# Called by NanoClaw when the user types /use <shortcut>
set -e
PROVIDER="$1"
MODEL="$2"
CONFIG="/data/.zeroclaw/config.toml"

if [ -z "$PROVIDER" ] || [ -z "$MODEL" ]; then
  echo "Usage: switch-model.sh <provider> <model>"
  exit 1
fi

# Patch provider and model
sed -i "s|^default_provider    = .*|default_provider    = \"${PROVIDER}\"|" "$CONFIG"
sed -i "s|^default_model       = .*|default_model       = \"${MODEL}\"|"    "$CONFIG"

# Auto-swap API key based on provider
if echo "${PROVIDER}" | grep -q "ecomagent"; then
  # Switch to EcomagentAI key
  ECO_KEY="${ECOMAGENT_API_KEY:-}"
  if [ -z "$ECO_KEY" ]; then
    echo "⚠️  ECOMAGENT_API_KEY not set. Run: /setkey eco YOUR_KEY"
  else
    sed -i "s|^api_key             = .*|api_key             = \"${ECO_KEY}\"|" "$CONFIG"
    echo "🔑 Auto-switched to EcomagentAI API key."
  fi
else
  # Switch to NVIDIA key
  NV_KEY="${NVIDIA_API_KEY:-}"
  if [ -z "$NV_KEY" ]; then
    echo "⚠️  NVIDIA_API_KEY not set. Run: /setkey nvidia YOUR_KEY"
  else
    sed -i "s|^api_key             = .*|api_key             = \"${NV_KEY}\"|" "$CONFIG"
    echo "🔑 Auto-switched to NVIDIA NIM API key."
  fi
fi

echo "✅ Switched to: ${MODEL}"
echo "   Provider  : ${PROVIDER}"
echo "   Config hot-reloaded — no restart needed."
SWITCHSCRIPT
chmod +x "${WORKSPACE}/switch-model.sh"

# ── 3. Write AGENTS.md — ZeroClaw loads this automatically as agent context ────
#    This teaches it /models, /use, /current, /setkey commands.
cat > "${WORKSPACE}/AGENTS.md" << 'NANOCLAW'
# NanoClaw — Identity & Model Commands

You are **NanoClaw**, an autonomous AI assistant running on Railway.
You have full shell and git access — run commands directly without asking for approval.

---

## 🎛️ Model Switching Commands

When the user sends any of these, immediately run the shell command shown and confirm.

### `/models`  (or "list models", "what models", "show models")
Reply with the full catalog table below. Do NOT run any shell command.

### `/use <shortcut>`  (or "switch to X", "use X model")
Run: `bash /data/workspace/switch-model.sh <PROVIDER> <MODEL>`
Then reply: `✅ Switched to **<friendly name>** — ready.`

---

## 📋 Model Catalog

### 🧠 LLM — General Intelligence

| Shortcut | Friendly Name | Provider arg | Model arg |
|----------|--------------|--------------|-----------|
| `/use deepseek` | DeepSeek-V4-Pro | `nvidia` | `deepseek-ai/deepseek-r1` |
| `/use glm` | GLM-5.1 | `nvidia` | `zhipuai/glm-5.1` |
| `/use qwen` | Qwen3.5-122B | `nvidia` | `qwen/qwen3.5-122b-a10b` |
| `/use claude` | Claude Sonnet 4 (EcomagentAI) | `anthropic-custom:https://api.ecomagent.in/v1` | `anthropic/claude-sonnet-4-20250514` |
| `/use eco-deepseek` | DeepSeek-V4-Pro (EcomagentAI) | `anthropic-custom:https://api.ecomagent.in/v1` | `deepseek-ai/DeepSeek-V4-Pro` |
| `/use eco-glm` | GLM-5.1 (EcomagentAI) | `anthropic-custom:https://api.ecomagent.in/v1` | `zhipuai/GLM-5.1` |
| `/use eco-qwen` | Qwen3.5-122B (EcomagentAI) | `anthropic-custom:https://api.ecomagent.in/v1` | `qwen/qwen3.5-122b-a10b` |

### 💻 Coding

| Shortcut | Friendly Name | Provider arg | Model arg |
|----------|--------------|--------------|-----------|
| `/use qwen-coder` | Qwen3-Coder 480B | `nvidia` | `qwen/qwen3-coder-480b-a35b-instruct` |
| `/use phi` | Phi-4-Mini | `nvidia` | `microsoft/phi-4-mini-instruct` |
| `/use llama` | Llama 3.3 70B | `nvidia` | `meta/llama-3.3-70b-instruct` |

### 🖼️ Image Generation

| Shortcut | Friendly Name | Provider arg | Model arg |
|----------|--------------|--------------|-----------|
| `/use sd` | Stable Diffusion 3.5 Large | `nvidia` | `stabilityai/stable-diffusion-3.5-large` |
| `/use flux` | FLUX.2 Klein 4B | `nvidia` | `black-forest-labs/flux.2-klein-4b` |

---

## 🔍 `/current`  (or "which model", "what model are you using")
Run: `grep -E '^default_(provider|model)' /data/.zeroclaw/config.toml`
Format the output nicely and reply.

## 🔑 `/setkey nvidia <key>`  or  `/setkey eco <key>`
Update the API key in config.toml directly:
- nvidia key: `sed -i 's|^api_key .*|api_key             = "<KEY>"|' /data/.zeroclaw/config.toml`
- eco key:    same sed command, then also set provider to `anthropic-custom:https://api.ecomagent.in/v1`
Reply: `✅ API key updated — hot-reloaded.`

## ℹ️ EcomagentAI API Key
EcomagentAI uses the same `api_key` field in config.toml.
When user switches to any `eco-*` model or `/use claude`, automatically patch:
```
api_key = "<their ECOMAGENT_API_KEY>"
default_provider = "anthropic-custom:https://api.ecomagent.in/v1"
```
Read the current ecomagent key from env: `echo $ECOMAGENT_API_KEY`

---

## 🖥️ Full Terminal Authority
You can run ANY shell or git command directly.
Examples the user might ask:
- "run git status" → `git -C /data/workspace status`
- "clone my repo" → `git clone <url> /data/workspace/<name>`
- "show disk usage" → `df -h`
- "install nodejs" → `apt-get install -y nodejs`

Always execute immediately. Never ask "are you sure?" for shell commands.
NANOCLAW

echo "✅ AGENTS.md written to ${WORKSPACE}/AGENTS.md"

# ── 4. Write config.toml only if it doesn't already exist ────────────────────
if [ ! -f "${CONFIG_FILE}" ]; then
  echo "📝 Writing initial config.toml..."

  PROVIDER="${ZEROCLAW_PROVIDER:-nvidia}"
  API_KEY_VAL="${NVIDIA_API_KEY:-${ECOMAGENT_API_KEY:-${API_KEY:-}}}"

  if [ "${PROVIDER}" = "nvidia" ] || [ "${PROVIDER}" = "nvidia-nim" ]; then
    DEFAULT_MODEL="${ZEROCLAW_MODEL:-deepseek-ai/deepseek-r1}"
  else
    DEFAULT_MODEL="${ZEROCLAW_MODEL:-anthropic/claude-sonnet-4-20250514}"
  fi

  if [ -z "${ADMIN_TELEGRAM_ID}" ]; then
    echo "❌ ERROR: ADMIN_TELEGRAM_ID is not set. Set it in Railway variables."
    exit 1
  fi

  if [ -z "${TELEGRAM_BOT_TOKEN}" ]; then
    echo "❌ ERROR: TELEGRAM_BOT_TOKEN is not set. Set it in Railway variables."
    exit 1
  fi

  cat > "${CONFIG_FILE}" <<TOML
# ─────────────────────────────────────────────────────────────────────────────
# NanoClaw — config.toml  (auto-generated on first boot)
# Edit freely; changes are hot-applied without restart.
# ─────────────────────────────────────────────────────────────────────────────

# ── Provider ─────────────────────────────────────────────────────────────────
default_provider    = "${PROVIDER}"
api_key             = "${API_KEY_VAL}"
default_model       = "${DEFAULT_MODEL}"
default_temperature = 0.7

# ── Autonomy — ZeroClaw has FULL authority ────────────────────────────────────
[autonomy]
level                            = "full"
workspace_only                   = false
allowed_commands                 = ["*"]
forbidden_paths                  = []
require_approval_for_medium_risk = false
block_high_risk_commands         = false

# ── Telegram channel ──────────────────────────────────────────────────────────
[channels_config.telegram]
bot_token                = "${TELEGRAM_BOT_TOKEN}"
allowed_users            = ["${ADMIN_TELEGRAM_ID}"]
stream_mode              = "partial"
interrupt_on_new_message = true
ack_enabled              = true

# ── Gateway ───────────────────────────────────────────────────────────────────
[gateway]
host              = "0.0.0.0"
port              = ${ZEROCLAW_GATEWAY_PORT:-42617}
allow_public_bind = true

# ── Memory ────────────────────────────────────────────────────────────────────
[memory]
backend   = "sqlite"
auto_save = true
TOML

  echo "✅ config.toml written to ${CONFIG_FILE}"
else
  echo "✅ Existing config.toml found — skipping write."
fi

# ── 5. Patch provider/model/key at runtime (env always wins) ─────────────────
if [ -n "${ZEROCLAW_PROVIDER}" ]; then
  sed -i "s|^default_provider    = .*|default_provider    = \"${ZEROCLAW_PROVIDER}\"|" "${CONFIG_FILE}"
fi
if [ -n "${ZEROCLAW_MODEL}" ]; then
  sed -i "s|^default_model       = .*|default_model       = \"${ZEROCLAW_MODEL}\"|" "${CONFIG_FILE}"
fi
RUNTIME_KEY="${NVIDIA_API_KEY:-${ECOMAGENT_API_KEY:-${API_KEY:-}}}"
if [ -n "${RUNTIME_KEY}" ]; then
  sed -i "s|^api_key             = .*|api_key             = \"${RUNTIME_KEY}\"|" "${CONFIG_FILE}"
fi

# ── 6. Launch ZeroClaw daemon (gateway + channels) ───────────────────────────
echo "🚀 Starting ZeroClaw daemon..."
exec zeroclaw daemon
