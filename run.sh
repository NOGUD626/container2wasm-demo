#!/usr/bin/env bash
#
# c2w ビルド → イメージ変換 → 配信サーバ起動 を一括実行する。
# 既にビルド済み / 変換済みの工程はスキップする。
#
# 使い方:
#   ./run.sh                          # 既定イメージ (riscv64/alpine:3.20)
#   ./run.sh riscv64/ubuntu:22.04     # イメージを指定して変換
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PORT="${PORT:-8080}"

# 1. c2w (未ビルドならビルド)
if [ ! -x "${SCRIPT_DIR}/bin/c2w" ]; then
  "${SCRIPT_DIR}/build-c2w.sh"
fi

# 2. out.wasm (未変換なら変換)
if [ ! -f "${SCRIPT_DIR}/htdocs/out.wasm" ]; then
  "${SCRIPT_DIR}/convert.sh" "$@"
fi

# 3. 配信 (Ctrl-C で停止)
echo "==> 配信開始: http://127.0.0.1:${PORT}/"
echo "==> ブラウザで上記 URL を開くと WASM 上でコンテナのシェルが起動します"
exec node "${SCRIPT_DIR}/serve.mjs"
