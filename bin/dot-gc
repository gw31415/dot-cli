#!/usr/bin/env fish
# dot-gc.fish - Nix ストアの不要なパスを削除するガベージコレクションコマンド
#
# Usage: dot-gc.fish [--aggressive]
#   引数なし:       現在使われていないパスのみを削除する  (nix store gc -v)
#   --aggressive:   全世代のプロファイルを削除してから徹底的にクリーンアップする
#                   (nix-collect-garbage -d)

# --- ログ関数 ---
function info;    echo "[INFO] $argv"; end
function success; echo "[SUCCESS] $argv"; end
function err;     echo "[ERROR] $argv" >&2; end

argparse 'aggressive' -- $argv
or begin
    err "Invalid arguments. Use --aggressive for a thorough cleanup."
    exit 1
end

info "Cleaning up..."

if set -q _flag_aggressive
    # 全世代のプロファイルを削除してから GC を実行する
    nix-collect-garbage -d
    or begin
        err "Failed to clean up."
        exit 1
    end
    success "Cleaned up aggressively."
else
    # 現在使われていないパスのみを削除する
    nix store gc -v
    or begin
        err "Failed to clean up."
        exit 1
    end
    success "Cleaned up."
end
