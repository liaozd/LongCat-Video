#!/usr/bin/env bash
# 下载数字人所需权重到数据盘，目录布局是硬要求：
#   <weights>/LongCat-Video            基础模型（avatar 脚本从 <avatar>/../LongCat-Video 读组件）
#   <weights>/LongCat-Video-Avatar-1.5 数字人权重
# 均走 ModelScope（国内快、支持断点续传，重跑即跳过已完成的文件）。
set -euo pipefail
cd "$(dirname "$0")/.."

WEIGHTS_DIR="${WEIGHTS_DIR:-/root/autodl-tmp/weights}"
BASE_DIR="$WEIGHTS_DIR/LongCat-Video"
AVATAR_DIR="$WEIGHTS_DIR/LongCat-Video-Avatar-1.5"

command -v modelscope >/dev/null || uv pip install modelscope --index-url https://pypi.tuna.tsinghua.edu.cn/simple

# ---------- 空间预检：数字人链路约需 75G ----------
AVAIL_KB=$(df -Pk "$WEIGHTS_DIR" 2>/dev/null | awk 'NR==2{print $4}')
if [ -z "$AVAIL_KB" ]; then AVAIL_KB=$(df -Pk /root/autodl-tmp | awk 'NR==2{print $4}'); fi
AVAIL_G=$((AVAIL_KB / 1024 / 1024))
echo "[INFO] 目标盘可用 ${AVAIL_G}G"
if [ "$AVAIL_G" -lt 80 ]; then
  echo "[WARN] 少于 80G，请先清理旧权重（多人版 avatar_multi、旧实例副本等）再继续"
  exit 1
fi

# ---------- 1. 基础模型：数字人只用这 4 个子目录（约 22.5G） ----------
# 基础 demo（文生视频/图生视频）才需要 dit/ 和 lora/（再加 56G），FULL_BASE=1 时全量下载。
if [ "${FULL_BASE:-0}" = "1" ]; then
  uv run modelscope download --model meituan-longcat/LongCat-Video --local_dir "$BASE_DIR"
else
  uv run modelscope download --model meituan-longcat/LongCat-Video --local_dir "$BASE_DIR" \
    --include "tokenizer/*" "text_encoder/*" "vae/*" "scheduler/*"
fi

# ---------- 2. Avatar 1.5 权重（INT8 + 蒸馏，4090 48G 可跑） ----------
uv run modelscope download --model meituan-longcat/LongCat-Video-Avatar-1.5 --local_dir "$AVATAR_DIR"

# ---------- 3. 校验 ----------
for d in "$BASE_DIR/tokenizer" "$BASE_DIR/text_encoder" "$BASE_DIR/vae" "$BASE_DIR/scheduler"; do
  [ -d "$d" ] || { echo "[FAIL] 缺少 $d"; exit 1; }
done
for d in "$AVATAR_DIR/base_model_int8" "$AVATAR_DIR/whisper-large-v3" "$AVATAR_DIR/scheduler" "$AVATAR_DIR/lora"; do
  [ -d "$d" ] || { echo "[FAIL] 缺少 $d"; exit 1; }
done
# 人声分离模型：1.5 仓库若不带，从 v1.0 目录或单独补齐（下面路径存在即可）
if [ ! -f "$AVATAR_DIR/vocal_separator/Kim_Vocal_2.onnx" ]; then
  echo "[WARN] 缺 $AVATAR_DIR/vocal_separator/Kim_Vocal_2.onnx"
  echo "       可从已下过的 v1.0 目录软链：ln -s <v1.0目录>/vocal_separator $AVATAR_DIR/vocal_separator"
fi
# ModelScope 下载中断会在 ._____temp 留半成品；应为空
LEFT=$(find "$BASE_DIR/._____temp" "$AVATAR_DIR/._____temp" -type f 2>/dev/null | wc -l)
if [ "$LEFT" -ne 0 ]; then echo "[WARN] ._____temp 里还有 $LEFT 个未完成文件，重跑本脚本续传"; fi
echo "[OK] 权重就绪：$BASE_DIR / $AVATAR_DIR"
