#!/usr/bin/env bash
# install.sh - gw31415/dotfiles の初期インストールスクリプト
#
# 実行条件:
#   - Nix がインストール済みであること
#   - nix-command と flakes の experimental features が有効であること
#
# 実行すると以下の処理を行う:
#   1. Nix と experimental features の確認
#   2. dotfiles リポジトリを $XDG_CONFIG_HOME/home-manager にクローン
#   3. env.nix の内容を確認して続行するかユーザーに尋ねる
#   4. home-manager switch を実行する

set -euo pipefail

# --- ログ関数 ---
info()    { echo "[INFO] $*"; }
warn()    { echo "[WARN] $*" >&2; }
success() { echo "[SUCCESS] $*"; }
error()   { echo "[ERROR] $*" >&2; }

echo "dot by @gw31415"
echo "GitHub: https://github.com/gw31415/dotfiles"
echo

info "Starting the setup process..."
info "Checking the environment..."

# --- config_home を決定 ---
# XDG_CONFIG_HOME が設定されていればそれを使用、なければ ~/.config を使用
if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    CONFIG_HOME="$XDG_CONFIG_HOME"
else
    CONFIG_HOME="$HOME/.config"
fi

HOME_MANAGER_PATH="$CONFIG_HOME/home-manager"
FLAKE_NIX="$HOME_MANAGER_PATH/flake.nix"
ENV_NIX="$HOME_MANAGER_PATH/env.nix"

info "Target path: $HOME_MANAGER_PATH"

# --- インストール済みチェック ---
if [ -f "$FLAKE_NIX" ]; then
    error "Already installed at $HOME_MANAGER_PATH."
    exit 1
fi

# --- Nix インストールチェック ---
if ! command -v nix > /dev/null 2>&1; then
    error "Nix is not installed. Please install Nix first."
    exit 1
fi
success "Nix is installed."

# --- experimental features チェック ---
# nix-command と flakes の両方が有効かどうか確認する
NIX_CONFIG=$(nix show-config 2>&1)
EXP_LINE=$(echo "$NIX_CONFIG" | grep 'experimental-features' | head -1)

if [ -z "$EXP_LINE" ]; then
    error "experimental-features is not set in Nix configuration."
    error "Please add the following to /etc/nix/nix.conf or ~/.config/nix/nix.conf:"
    error "  experimental-features = nix-command flakes"
    exit 1
fi

if ! echo "$EXP_LINE" | grep -q 'nix-command' || ! echo "$EXP_LINE" | grep -q 'flakes'; then
    error "nix-command and/or flakes are not enabled."
    error "Please add the following to your Nix configuration:"
    error "  experimental-features = nix-command flakes"
    exit 1
fi
success "nix-command and flakes are set."

# --- ターゲットパスの存在チェック ---
if [ -e "$HOME_MANAGER_PATH" ]; then
    error "The target path $HOME_MANAGER_PATH already exists. Please remove it first."
    exit 1
fi

# --- config_home ディレクトリを作成 ---
mkdir -p "$CONFIG_HOME"

# --- dotfiles をクローン ---
info "Cloning the dotfiles..."
git clone https://github.com/gw31415/dotfiles "$HOME_MANAGER_PATH"
success "Downloaded dotfiles to $HOME_MANAGER_PATH."

# --- env.nix の確認 ---
# env.nix にユーザー固有の設定が含まれている場合、内容を表示して続行を確認する
if [ -f "$ENV_NIX" ]; then
    echo
    echo "> $ENV_NIX"
    cat "$ENV_NIX"
    echo
    info "If the information in $ENV_NIX does not match, the build will fail."
    info "You can edit $ENV_NIX before running the next command."

    printf "Continue installation? [Y/n] "
    read -r ANSWER

    case "${ANSWER:-y}" in
        [nN]*)
            echo "Choose an action:"
            echo "  1) Leave $HOME_MANAGER_PATH  (edit env.nix and run the command again)"
            echo "  2) Remove $HOME_MANAGER_PATH (re-run the script to download again)"
            printf "Enter choice [1/2]: "
            read -r CHOICE

            case "${CHOICE:-1}" in
                2)
                    rm -rf "$HOME_MANAGER_PATH"
                    info "Removed the downloaded dotfiles."
                    ;;
                *)
                    info "Please edit $ENV_NIX and re-run the script to continue."
                    ;;
            esac
            exit 0
            ;;
    esac
fi

# --- home-manager switch ---
# home-manager がパスにない場合は nix path-info でストアパスを取得する
info "Switching home-manager..."

if command -v home-manager > /dev/null 2>&1; then
    HM_BIN="home-manager"
else
    NIX_HM_PATH=$(nix path-info nixpkgs#home-manager 2>/dev/null | tr -d '[:space:]')
    if [ -n "$NIX_HM_PATH" ] && [ -x "$NIX_HM_PATH/bin/home-manager" ]; then
        HM_BIN="$NIX_HM_PATH/bin/home-manager"
    else
        HM_BIN="home-manager"
    fi
fi

(cd "$HOME_MANAGER_PATH" && "$HM_BIN" switch)
success "Success."
