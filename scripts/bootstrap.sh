#!/usr/bin/env bash
set -e

# ============================================
# OpenClaw Agent Bootstrap Script
# Restores core skills and loads user-defined
# tools on every container start.
# ============================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${BLUE}[bootstrap]${NC} $1"; }
ok()   { echo -e "${GREEN}[bootstrap]${NC} $1"; }
warn() { echo -e "${YELLOW}[bootstrap]${NC} $1"; }

info "Starting agent bootstrap..."

# ============================================
# 1. Core Skills (hard-coded)
# ============================================

# --- gog CLI v0.9.0 ---
if ! command -v gog &>/dev/null || [[ "$(gog --version 2>/dev/null | head -1)" != *"v0.9.0"* ]]; then
    info "Installing gog CLI v0.9.0..."
    GOG_URL="https://github.com/steipete/gogcli/releases/download/v0.9.0/gog_linux_amd64.tar.gz"
    curl -fsSL "$GOG_URL" -o /tmp/gog.tar.gz
    tar -xzf /tmp/gog.tar.gz -C /tmp
    mv /tmp/gog /usr/local/bin/gog
    chmod +x /usr/local/bin/gog
    rm -f /tmp/gog.tar.gz
    ok "gog v0.9.0 installed"
else
    ok "gog v0.9.0 already installed"
fi

# --- himalaya v1.1.0 ---
if ! command -v himalaya &>/dev/null || [[ "$(himalaya --version 2>/dev/null)" != *"1.1.0"* ]]; then
    info "Installing himalaya v1.1.0..."
    HIMALAYA_URL="https://github.com/pimalaya/himalaya/releases/download/v1.1.0/himalaya.linux.x86_64.musl.tar.gz"
    curl -fsSL "$HIMALAYA_URL" -o /tmp/himalaya.tar.gz
    tar -xzf /tmp/himalaya.tar.gz -C /tmp
    mv /tmp/himalaya /usr/local/bin/himalaya
    chmod +x /usr/local/bin/himalaya
    rm -f /tmp/himalaya.tar.gz
    ok "himalaya v1.1.0 installed"
else
    ok "himalaya v1.1.0 already installed"
fi

# --- python3 & pip ---
if ! command -v python3 &>/dev/null; then
    info "Installing python3 and pip..."
    apt-get update -qq && apt-get install -y -qq python3 python3-pip >/dev/null 2>&1
    ok "python3 and pip installed"
else
    ok "python3 already available"
fi

if ! command -v pip3 &>/dev/null && ! python3 -m pip --version &>/dev/null 2>&1; then
    info "Installing pip..."
    apt-get update -qq && apt-get install -y -qq python3-pip >/dev/null 2>&1
    ok "pip installed"
fi

# ============================================
# 2. Dynamic OS Tools (apt-packages.txt)
# ============================================

APT_MANIFEST="/home/node/apt-packages.txt"
if [[ -f "$APT_MANIFEST" ]]; then
    # Read non-empty, non-comment lines; normalize commas to spaces
    PACKAGES=$(grep -v '^\s*#' "$APT_MANIFEST" | grep -v '^\s*$' | tr ',' ' ' | tr '\n' ' ')
    if [[ -n "$PACKAGES" ]]; then
        info "Installing OS packages: $PACKAGES"
        apt-get update -qq && apt-get install -y -qq $PACKAGES >/dev/null 2>&1
        ok "OS packages installed"
    fi
else
    info "No apt-packages.txt found — skipping OS tools"
fi

# ============================================
# 3. Dynamic Python Packages (requirements.txt)
# ============================================

REQUIREMENTS="/home/node/requirements.txt"
if [[ -f "$REQUIREMENTS" ]]; then
    info "Installing Python packages from requirements.txt..."
    pip3 install -r "$REQUIREMENTS" --break-system-packages -q 2>/dev/null \
        || python3 -m pip install -r "$REQUIREMENTS" --break-system-packages -q
    ok "Python packages installed"
else
    info "No requirements.txt found — skipping Python packages"
fi

# ============================================
# Done — hand off to the main process
# ============================================

ok "Bootstrap complete! Starting OpenClaw agent..."
exec "$@"
