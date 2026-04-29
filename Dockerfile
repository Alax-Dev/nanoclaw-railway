# ─────────────────────────────────────────────────────────────────────────────
# NanoClaw Railway Image
# Based on the official ZeroClaw Debian image.
# Customisations:
#   1. NVIDIA NIM + EcomagentAI (OpenAI-compatible) provider support
#   2. Telegram-only channel, admin-ID restricted
#   3. Full autonomy (YOLO) — ZeroClaw itself runs all terminal / git commands
# ─────────────────────────────────────────────────────────────────────────────

FROM ghcr.io/zeroclaw-labs/zeroclaw:debian

# Persist state here (Railway volume mounted at /data)
ENV HOME=/data
ENV ZEROCLAW_WORKSPACE=/data/workspace
ENV ZEROCLAW_CONFIG_PATH=/data/.zeroclaw/config.toml

# Runtime defaults — Railway injects PORT automatically
ENV PORT=42617
ENV ZEROCLAW_GATEWAY_PORT=42617

# Provider selection (overridable via Railway env vars)
# Set ZEROCLAW_PROVIDER=nvidia  OR  custom:https://api.ecomagent.in/  at deploy time
ENV ZEROCLAW_PROVIDER=nvidia

# Copy start script (--chmod avoids permission errors on non-root images)
COPY --chmod=755 start.sh /start.sh

EXPOSE 42617

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${ZEROCLAW_GATEWAY_PORT:-42617}/health || exit 1

CMD ["/start.sh"]
