#!/usr/bin/env bash
#
# コンテナイメージを WASM (WASI) に変換し htdocs/out.wasm を生成する。
#
# 使い方:
#   ./convert.sh                          # 既定: riscv64/alpine:3.20 (軽量/高速)
#   ./convert.sh riscv64/ubuntu:22.04     # 別の riscv64 イメージ
#   ARCH=amd64 ./convert.sh ubuntu:22.04  # x86_64 (Bochs, 低速だが本物の Ubuntu)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly C2W="${SCRIPT_DIR}/bin/c2w"
readonly OUT="${SCRIPT_DIR}/htdocs/out.wasm"
readonly DEFAULT_IMAGE="riscv64/alpine:3.20"
# 変換先 CPU アーキ: riscv64=TinyEMU(軽量), amd64=Bochs(重い), aarch64=QEMU
readonly ARCH="${ARCH:-riscv64}"

IMAGE="${1:-$DEFAULT_IMAGE}"

# --- 事前チェック (guard clause) ---
if [ ! -x "$C2W" ]; then
  echo "エラー: c2w が未ビルドです。先に ./build-c2w.sh を実行してください。" >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "エラー: Docker デーモンに接続できません。Docker Desktop を起動してください。" >&2
  exit 1
fi

echo "==> 変換 image=${IMAGE} arch=${ARCH}"
echo "==> 出力 ${OUT}"
echo "==> 初回は TinyEMU/Linux カーネルのビルドで 10〜20 分かかります"
mkdir -p "$(dirname "$OUT")"

start_ts="$(date +%s)"
DOCKER_BUILDKIT=1 "$C2W" --target-arch="$ARCH" "$IMAGE" "$OUT"
elapsed="$(( $(date +%s) - start_ts ))"

echo "==> 変換完了 (${elapsed}s)"
ls -lh "$OUT"
