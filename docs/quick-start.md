# Quick Start Guide (5 Minutes)

Get started with LongCat-Video in under 5 minutes.

## What is LongCat-Video?

LongCat-Video is a 13.6B parameter video generation model that supports:
- **Text-to-Video**: Generate videos from text descriptions
- **Image-to-Video**: Animate static images
- **Video Continuation**: Extend existing videos seamlessly
- **Avatar**: Audio-driven human video generation (single & multi-person)

## Installation

```bash
# Clone the repo
git clone --single-branch --branch main https://github.com/meituan-longcat/LongCat-Video
cd LongCat-Video

# Create conda environment
conda create -n longcat-video python=3.10
conda activate longcat-video

# Install torch (adjust for your CUDA version)
pip install torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124

# Install flash-attn-2
pip install ninja psutil packaging
pip install flash_attn==2.7.4.post1

# Install core requirements
pip install -r requirements.txt

# Install avatar requirements
conda install -c conda-forge librosa ffmpeg
pip install -r requirements_avatar.txt
```

## Download Model

```bash
pip install "huggingface_hub[cli]"

# For text/image/video generation
huggingface-cli download meituan-longcat/LongCat-Video --local-dir ./weights/LongCat-Video

# For avatar generation (recommended v1.5)
huggingface-cli download meituan-longcat/LongCat-Video-Avatar-1.5 --local-dir ./weights/LongCat-Video-Avatar-1.5
```

## Generate Your First Video

### Text-to-Video (Single GPU)

```bash
torchrun run_demo_text_to_video.py --checkpoint_dir=./weights/LongCat-Video --enable_compile
```

Output: `output_text_to_video.mp4`

### Avatar Generation (Single GPU)

```bash
torchrun run_demo_avatar_single_audio_to_video.py \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --input_json=assets/avatar/single_example_1.json \
  --use_distill \
  --model_type avatar-v1.5 \
  --use_int8
```

Output: `output_avatar_single.mp4`

## Next Steps

- **Learn all generation modes**: See [Generation Modes](generation-modes.md)
- **Optimize for your hardware**: See [Advanced Configuration](advanced-configuration.md)
- **Explore detailed specs**: Check `openspec/specs/` for comprehensive capability documentation

## Troubleshooting

**Out of memory**: Reduce resolution or use multi-GPU with `--context_parallel_size=2`

**Slow generation**: Add `--enable_compile` for torch.compile optimization

**Avatar lip sync issues**: Increase `--audio_cfg` to 3-5 for better synchronization
