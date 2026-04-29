# 🦀 NanoClaw — ZeroClaw on Railway

> Deploy [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) on Railway with NVIDIA NIM, EcomagentAI support, admin-only Telegram bot, and full terminal autonomy.

---

## What is this?

**NanoClaw** is a customised Railway deployment of ZeroClaw — a fast, lightweight, Rust-based autonomous AI assistant.

Three things are changed from stock ZeroClaw:

| # | Change | What it does |
|---|--------|--------------|
| 1 | **NVIDIA NIM + EcomagentAI providers** | Use `nvapi-*` keys for NVIDIA NIM or `https://api.ecomagent.in` for an Anthropic-compatible endpoint |
| 2 | **Telegram-only, admin-ID locked** | Only YOUR Telegram numeric ID can talk to the bot |
| 3 | **Full terminal authority** | ZeroClaw itself can run any shell/git command directly from chat — no approval gates |

---

## Supported Models

### 🧠 LLM (General Intelligence)
| Model | Provider | Notes |
|-------|----------|-------|
| `deepseek-ai/deepseek-r1` | NVIDIA NIM | DeepSeek-V4-Pro equivalent |
| `zhipuai/glm-5.1` | NVIDIA NIM / EcomagentAI | GLM-5.1 |
| `qwen/qwen3.5-122b-a10b` | NVIDIA NIM / EcomagentAI | Qwen3.5-122B |
| `anthropic/claude-sonnet-4-20250514` | EcomagentAI only | Claude Sonnet 4 |

### 💻 Coding
| Model | Provider |
|-------|----------|
| `qwen/qwen3-coder-480b-a35b-instruct` | NVIDIA NIM |
| `microsoft/phi-4-mini-instruct` | NVIDIA NIM |
| `meta/llama-3.3-70b-instruct` | NVIDIA NIM |

### 🖼️ Image Generation
| Model | Provider |
|-------|----------|
| `stabilityai/stable-diffusion-3.5-large` | NVIDIA NIM |
| `black-forest-labs/flux.2-klein-4b` | NVIDIA NIM |

---

## Deploy to Railway

### Step 1 — Fork this repo

Fork `nanoclaw-railway` to your GitHub account.

### Step 2 — Create Railway project

1. Go to [railway.app](https://railway.app) → **New Project**
2. Select **Deploy from GitHub repo** → pick your fork
3. Railway will detect `railway.toml` and `Dockerfile` automatically

### Step 3 — Add a Volume

Railway needs persistent storage so config and memory survive redeploys:

1. In your service → **Settings → Volumes**
2. Add volume, mount path: `/data`

### Step 4 — Set Environment Variables

Go to your service → **Variables** and add these (copy from `.env.example`):

#### Required (always)
```
TELEGRAM_BOT_TOKEN   = 123456:your_bot_token
ADMIN_TELEGRAM_ID    = 987654321        ← your numeric Telegram ID
```

#### For NVIDIA NIM
```
ZEROCLAW_PROVIDER    = nvidia
NVIDIA_API_KEY       = nvapi-xxxxxxxxxxxx
ZEROCLAW_MODEL       = deepseek-ai/deepseek-r1
```

#### For EcomagentAI
```
ZEROCLAW_PROVIDER    = anthropic-custom:https://api.ecomagent.in/v1
ECOMAGENT_API_KEY    = your-ecomagent-key
ZEROCLAW_MODEL       = anthropic/claude-sonnet-4-20250514
```

#### Port (keep defaults)
```
PORT                 = 42617
ZEROCLAW_GATEWAY_PORT = 42617
```

### Step 5 — Deploy

Click **Deploy**. Railway builds the Docker image and starts the bot.

Watch logs — you'll see:
```
🦀 NanoClaw starting up...
📝 Writing initial config.toml...
✅ config.toml written to /data/.zeroclaw/config.toml
🚀 Starting ZeroClaw daemon...
```

### Step 6 — Test on Telegram

Open your bot in Telegram and send a message. Only your `ADMIN_TELEGRAM_ID` will get a response — everyone else is silently ignored.

---

## 🎛️ Switching Models from Telegram

No Railway dashboard needed. Just type in Telegram:

### See all models
```
/models
```
Returns the full catalog table.

### Switch instantly
```
/use deepseek      ← DeepSeek-V4-Pro (NVIDIA NIM)
/use glm           ← GLM-5.1 (NVIDIA NIM)
/use qwen          ← Qwen3.5-122B (NVIDIA NIM)
/use claude        ← Claude Sonnet 4 (EcomagentAI)
/use eco-deepseek  ← DeepSeek-V4-Pro (EcomagentAI)
/use eco-glm       ← GLM-5.1 (EcomagentAI)
/use eco-qwen      ← Qwen3.5-122B (EcomagentAI)
/use qwen-coder    ← Qwen3-Coder 480B (coding)
/use phi           ← Phi-4-Mini (coding)
/use llama         ← Llama 3.3 70B (coding)
/use sd            ← Stable Diffusion 3.5 Large (image)
/use flux          ← FLUX.2 Klein 4B (image)
```

Switching is **instant** — ZeroClaw edits its own `config.toml` directly. No redeploy, no Railway dashboard.

### Check current model
```
/current
```

### Update API key from Telegram
```
/setkey nvidia nvapi-xxxxxxxxxxxx
/setkey eco your-ecomagent-key
```

---

## Full Autonomy — ZeroClaw Runs Terminal Commands

NanoClaw is configured with `[autonomy] level = "full"` and `allowed_commands = ["*"]`.

This means **ZeroClaw itself** (not you) can:

- Run any shell command: `ls`, `cat`, `curl`, `python`, `node`, etc.
- Run `git` commands: clone, commit, push, pull, branch, etc.
- Read and write files anywhere on `/data`
- Install packages, execute scripts, build projects

You just ask it in natural language from Telegram:

> "Clone my repo from GitHub and show me the latest commit"  
> "Run the test suite and tell me what failed"  
> "Commit all changes with message 'fix: update deps' and push"

ZeroClaw handles it — you don't type a single terminal command.

---

## Customising the Config

After first boot, the config lives at `/data/.zeroclaw/config.toml` inside the Railway volume. Edit it via Railway's terminal:

```bash
# Open Railway terminal from your service dashboard
nano /data/.zeroclaw/config.toml
```

Changes are **hot-applied** — no restart needed for most settings.

To add more admin IDs (e.g. a team member):
```toml
[channels_config.telegram]
allowed_users = ["123456789", "987654321", "anotheruser"]
```

---

## Architecture

```
Telegram Bot API
      │
      ▼
 ZeroClaw daemon  (zeroclaw daemon)
      │
      ├── [channels_config.telegram]  ← admin-only allowlist
      │
      ├── [autonomy] level = "full"   ← full shell/git access
      │
      └── Provider routing
            ├── nvidia          → https://integrate.api.nvidia.com/v1
            └── anthropic-custom → https://api.ecomagent.in/v1

  Persistent state: /data  (Railway volume)
    ├── .zeroclaw/config.toml
    ├── .zeroclaw/sessions/
    ├── .zeroclaw/memory/
    └── workspace/
```

---

## Troubleshooting

### Bot not responding
- Check `ADMIN_TELEGRAM_ID` is your **numeric** ID (not username)
- Find your ID with [@userinfobot](https://t.me/userinfobot) on Telegram
- Check Railway logs for errors

### Provider errors
- For NVIDIA NIM: verify `NVIDIA_API_KEY` starts with `nvapi-`
- For EcomagentAI: verify `ECOMAGENT_API_KEY` is valid and provider URL is correct
- Check the model name is exactly as listed in the table above

### Config not updating
- Config is only written on **first boot** when `/data/.zeroclaw/config.toml` doesn't exist
- To reset config: delete the file via Railway terminal then redeploy

### Volume not persisting
- Ensure Railway volume is mounted at `/data` in your service settings

---

## Credits

Built on [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) — Apache 2.0 licensed.  
NanoClaw Railway template by Aman Khan.
