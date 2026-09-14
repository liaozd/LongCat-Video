#!/usr/bin/env bash
# AutoDL 全新容器一键装 LongCat-Video 环境（无卡模式下即可执行）。
# 前提：仓库克隆到 ~/LongCat-Video-github，用 uv 管理 .venv。
# 所有版本结论都来自实机验证，改之前先看注释里的原因。
set -euo pipefail
cd "$(dirname "$0")/.."

PIP_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"

# ---------- 1. uv 与 venv ----------
command -v uv >/dev/null || pip install -U uv -i "$PIP_INDEX"
uv venv --python 3.12

# ---------- 2. torch（requirements 钉死 2.6.0，PyPI Linux 版自带 cu124） ----------
uv pip install torch==2.6.0 --index-url "$PIP_INDEX"

# ---------- 3. 主依赖（flash-attn 必须最后单独装，见第 4 步） ----------
grep -v '^flash-attn' requirements.txt > /tmp/requirements-noflash.txt
uv pip install -r /tmp/requirements-noflash.txt --index-url "$PIP_INDEX"

# ---------- 4. flash-attn：只能用官方预编译 wheel ----------
# 无卡模式没有 GPU/大内存，源码编译必挂；且 PyPI 只有 sdist。
# 关键坑：官方 PyPI torch 2.6.0 是【旧 ABI】（torch.compiled_with_cxx11_abi()==False），
# 所以必须选 cxx11abiFALSE 的 wheel，选 TRUE 会得到 undefined symbol 报错。
# 下面按 venv 里 torch 的实际 ABI / 版本自动拼出 wheel 名，不再靠猜。
ABI=$(uv run python -c "import torch; print('TRUE' if torch.compiled_with_cxx11_abi() else 'FALSE')")
TWW=$(uv run python -c "import torch; v=torch.__version__.split('+')[0].split('.'); print(v[0]+'.'+v[1])")
FLASH_ATTN_VER="2.7.4.post1"
WHEEL="flash_attn-${FLASH_ATTN_VER}+cu12torch${TWW}cxx11abi${ABI}-cp312-cp312-linux_x86_64.whl"
echo "[INFO] flash-attn wheel: $WHEEL"
# GitHub 直连慢，AutoDL 提供学术加速（注意：开着它走 pip 源会变慢，所以只在这一步临时开）
if [ -f /etc/network_turbo ]; then source /etc/network_turbo; fi
uv pip install "https://github.com/Dao-AILab/flash-attention/releases/download/v${FLASH_ATTN_VER}/${WHEEL}"
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY

# ---------- 5. 数字人（avatar）依赖 ----------
# requirements_avatar.txt 有三处问题（实机验证）：
#   libsndfile1        —— apt 系统包，PyPI 上没有，直接剔除
#   tritonserverclient —— 代码从未 import，剔除
#   onnxruntime==1.16.3—— 无 Python 3.12 轮子，换 >=1.17
# 另外必须装 accelerate：否则 diffusers 加载权重不走 low_cpu_mem_usage，内存翻倍。
grep -vE '^(libsndfile1|tritonserverclient|onnxruntime)' requirements_avatar.txt > /tmp/requirements-avatar.txt
uv pip install -r /tmp/requirements-avatar.txt "onnxruntime>=1.17" accelerate --index-url "$PIP_INDEX"

# ---------- 6. ffmpeg：audio_separator 与合成音轨都依赖可执行文件 ----------
command -v ffmpeg >/dev/null || { apt-get update -qq && apt-get install -y -qq ffmpeg; }

# ---------- 7. 自检 ----------
export OMP_NUM_THREADS=8   # AutoDL 镜像里该变量常为非法值，libgomp 会告警
uv run python - <<'PY'
import torch, flash_attn, librosa, audio_separator, onnxruntime, accelerate
print("[OK] torch", torch.__version__, "| cxx11abi", torch.compiled_with_cxx11_abi(),
      "| flash_attn", flash_attn.__version__, "| cuda available:", torch.cuda.is_available())
PY
echo "环境就绪。下一步：bash scripts/download_weights.sh"
