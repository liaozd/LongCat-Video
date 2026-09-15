#!/usr/bin/env bash
# 跑 Avatar 1.5 数字人推理（单卡 4090 48G：INT8 + 蒸馏 8 步）。
# 用法：bash scripts/run_avatar_15.sh <input_json> [resolution(480p|720p)]
#
# 两个实机教训固化在这里：
# 1) 中间产物绝不写 /root/autodl-fs（网络盘）：代码每完成一段就把【累计的全部帧】
#    重新编码写盘一次，段数越多越慢（近似平方增长），网络盘会把这个成本再放大数倍。
#    所以先写本地 OUT_DIR，结束后只把成品 mp4 拷到 COPY_TO。
# 2) 段数不用手动算：run_demo_avatar_single_calm.py 会按音频时长自动分段
#    （1.5 为 25fps，首段 93 帧(3.72s)，后续每段净增 80 帧(3.2s)）。
set -euo pipefail
cd "$(dirname "$0")/.."

INPUT_JSON="${1:?用法: bash scripts/run_avatar_15.sh <input_json> [resolution]}"
RESOLUTION="${2:-480p}"

WEIGHTS_DIR="${WEIGHTS_DIR:-/root/autodl-tmp/weights/LongCat-Video-Avatar-1.5}"
OUT_DIR="${OUT_DIR:-/root/outputs/avatar}"   # 本地盘！别指向 autodl-fs
COPY_TO="${COPY_TO:-/root/autodl-fs}"        # 置空则不拷贝

export OMP_NUM_THREADS="${OMP_NUM_THREADS:-8}"
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

echo "[INFO] resolution=${RESOLUTION}，num_segments 由脚本按音频时长自动计算"
echo "[INFO] 中间产物 -> ${OUT_DIR}（本地盘），成品拷至 ${COPY_TO:-<不拷贝>}"

mkdir -p "$OUT_DIR"
# calm 变体：默认 negative_prompt 已去掉 static/still picture（否则反向鼓励夸张动作），
# 可在 input JSON 里加 "negative_prompt" 字段覆盖。
# 需要换音频时给脚本加 --audio_path /path/to/x.wav，分段数会按新音频自动重算。
uv run torchrun --nproc_per_node=1 run_demo_avatar_single_calm.py \
  --input_json "$INPUT_JSON" \
  --checkpoint_dir "$WEIGHTS_DIR" \
  --model_type avatar-v1.5 --use_int8 --use_distill \
  --stage_1 ai2v --resolution "$RESOLUTION" \
  --output_dir "$OUT_DIR"

if [ -n "$COPY_TO" ]; then
  find "$OUT_DIR" -name '*.mp4' -newermt '-1 day' -exec cp -f --target-directory "$COPY_TO" {} +
  echo "[OK] 成品已拷贝到 $COPY_TO"
fi

# 显存备注：480p 时 KV cache 已把 48G 卡用到 ~47.9G（脚本内 offload_kv_cache=False 写死）。
# 段数再加多或尝试 720p 可能 CUDA OOM，届时需要改 run_demo_avatar_single_calm.py:348。
