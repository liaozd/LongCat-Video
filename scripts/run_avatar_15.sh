#!/usr/bin/env bash
# 跑 Avatar 1.5 数字人推理（单卡 4090 48G：INT8 权重 + CFG 收敛表情/口型）。
# 用法：bash scripts/run_avatar_15.sh <input_json> [resolution(480p|720p)]
#   冒烟测试（只跑 1 段验证显存/效果）：SEGMENTS=1 bash scripts/run_avatar_15.sh ...
#
# 三个实机教训固化在这里：
# 1) 中间产物绝不写 /root/autodl-fs（网络盘）：代码每完成一段就把【累计的全部帧】
#    重新编码写盘一次，段数越多越慢（近似平方增长），网络盘会把这个成本再放大数倍。
#    所以先写本地 OUT_DIR，结束后只把成品 mp4 拷到 COPY_TO。
# 2) 段数不用手动算：run_demo_avatar_single_calm.py 会按音频时长自动分段
#    （1.5 为 25fps，首段 93 帧(3.72s)，后续每段净增 80 帧(3.2s)）。
# 3) 表情/口型收敛：蒸馏模式(--use_distill)会关掉 CFG，audio_guidance_scale 失效，
#    音频以全强度直连 DiT，表情口型必然夸张。所以默认走非蒸馏 CFG 路径，
#    audio_guidance_scale=1.0（音频贡献 1:1 注入，不外推放大）。
#    代价：25 步 CFG ≈ 蒸馏 8 步的 ~9 倍 DiT 计算量，这里取 15 步折中。
#    想要快回去（表情夸张可接受）：把 --use_distill 加回来即可。
set -euo pipefail
cd "$(dirname "$0")/.."

INPUT_JSON="${1:?用法: bash scripts/run_avatar_15.sh <input_json> [resolution]}"
RESOLUTION="${2:-480p}"
SEGMENTS="${SEGMENTS:-0}"              # 0 = 按音频时长自动；冒烟测试设 1

WEIGHTS_DIR="${WEIGHTS_DIR:-/root/autodl-tmp/weights/LongCat-Video-Avatar-1.5}"
OUT_DIR="${OUT_DIR:-/root/outputs/avatar}"   # 本地盘！别指向 autodl-fs
COPY_TO="${COPY_TO:-/root/autodl-fs}"        # 置空则不拷贝

export OMP_NUM_THREADS="${OMP_NUM_THREADS:-8}"
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

echo "[INFO] resolution=${RESOLUTION}，num_segments=${SEGMENTS}(0=自动)，audio_guidance_scale=1.0(CFG)"
echo "[INFO] 中间产物 -> ${OUT_DIR}（本地盘），成品拷至 ${COPY_TO:-<不拷贝>}"

mkdir -p "$OUT_DIR"
# calm 变体：默认 negative_prompt 已去掉 static/still picture（否则反向鼓励夸张动作），
# 可在 input JSON 里加 "negative_prompt" 字段覆盖。
# 换音频时给脚本加 --audio_path /path/to/x.wav，分段数会按新音频自动重算。
uv run torchrun --nproc_per_node=1 run_demo_avatar_single_calm.py \
  --input_json "$INPUT_JSON" \
  --checkpoint_dir "$WEIGHTS_DIR" \
  --model_type avatar-v1.5 --use_int8 \
  --num_inference_steps 15 --audio_guidance_scale 1.0 \
  --num_segments "$SEGMENTS" \
  --stage_1 ai2v --resolution "$RESOLUTION" \
  --output_dir "$OUT_DIR"

if [ -n "$COPY_TO" ]; then
  find "$OUT_DIR" -name '*.mp4' -newermt '-1 day' -exec cp -f --target-directory "$COPY_TO" {} +
  echo "[OK] 成品已拷贝到 $COPY_TO"
fi

# 显存备注：CFG 模式每步做 batch-2 + batch-1 两次前向，激活峰值高于蒸馏模式，
# 因此 calm 脚本里 offload_kv_cache=True（KV cache 卸载 CPU）。若仍 OOM，
# 下一步是推理前把 text_encoder 卸载到 CPU（改 run_demo_avatar_single_calm.py 模型加载段）。
