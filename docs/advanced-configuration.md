# Advanced Configuration

Production-level configuration for performance optimization and customization.

## Multi-GPU Setup

Scale generation across multiple GPUs for faster inference and higher resolution.

### Context Parallel

Context parallel splits the generation workload across GPUs along the temporal dimension.

**Basic Multi-GPU:**
```bash
torchrun --nproc_per_node=2 run_demo_text_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

**4-GPU Setup:**
```bash
torchrun --nproc_per_node=4 run_demo_text_to_video.py \
  --context_parallel_size=4 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

### When to Use Multi-GPU

- **Higher resolution**: 720p+ requires more VRAM
- **Longer videos**: More frames need more memory
- **Faster generation**: Parallel processing reduces wall time
- **Batch processing**: Generate multiple videos simultaneously

### GPU Requirements

| Configuration | VRAM per GPU | Total VRAM | Recommended For |
|---------------|--------------|-------------|-----------------|
| Single GPU | 24GB | 24GB | 480p, short videos |
| 2 GPUs | 16GB | 32GB | 720p, medium videos |
| 4 GPUs | 12GB | 48GB | 720p+, long videos |
| 8 GPUs | 8GB | 64GB | Production batch processing |

### Distributed Setup

For multi-node setups, use PyTorch distributed:

```bash
# Node 0 (master)
torchrun --nproc_per_node=4 --nnodes=2 --node_rank=0 \
  --master_addr="192.168.1.1" --master_port=29500 \
  run_demo_text_to_video.py --context_parallel_size=8

# Node 1
torchrun --nproc_per_node=4 --nnodes=2 --node_rank=1 \
  --master_addr="192.168.1.1" --master_port=29500 \
  run_demo_text_to_video.py --context_parallel_size=8
```

---

## Model Variants

Choose the right model variant for your use case.

### LongCat-Video Models

| Model | Parameters | Use Case | Strengths |
|-------|------------|----------|-----------|
| LongCat-Video | 13.6B | General video generation | Unified T2V/I2V/VC, long video support |
| LongCat-Video-Avatar v1.0 | 13.6B + audio encoder | Avatar generation | Wav2Vec2 audio, proven stability |
| LongCat-Video-Avatar v1.5 | 13.6B + Whisper | Avatar generation (recommended) | Better lip sync, distillation, INT8 |

### Avatar Version Comparison

**v1.5 Advantages:**
- Whisper-large-v3 encoder: 20-30% better lip synchronization
- Step distillation: 8-step inference (vs 50 steps) = 6x faster
- INT8 quantization: 40% VRAM reduction
- Production-ready temporal stability

**v1.0 Use Cases:**
- Legacy compatibility
- Research comparisons
- When Wav2Vec2 features are specifically needed

### Model Selection Guide

```
Text/Image/Video Generation → LongCat-Video
Avatar (production) → Avatar v1.5
Avatar (research/legacy) → Avatar v1.0
Low VRAM environment → Avatar v1.5 + INT8
Maximum quality → Avatar v1.5 + FP16
```

---

## Attention Mechanisms

Optimize attention computation for your hardware.

### Available Attention Types

| Attention Type | Speed | VRAM | Hardware Requirements |
|----------------|-------|------|----------------------|
| FlashAttention-2 | Fast | Medium | CUDA 11.8+, Ampere+ |
| FlashAttention-3 | Fastest | Low | Hopper (H100+) |
| xFormers | Medium | Low | CUDA 11.3+ |
| Block Sparse Attention | Variable | Lowest | Custom implementation |

### Configuring Attention

Edit `./weights/LongCat-Video/dit/config.json`:

```json
{
  "attention_type": "flash_attn_2",
  "enable_bsa": false
}
```

**Enable FlashAttention-3 (H100+):**
```json
{
  "attention_type": "flash_attn_3",
  "enable_bsa": false
}
```

**Enable xFormers:**
```json
{
  "attention_type": "xformers",
  "enable_bsa": false
}
```

**Enable Block Sparse Attention:**
```json
{
  "attention_type": "flash_attn_2",
  "enable_bsa": true,
  "bsa_params": {
    "block_size": 64,
    "sparse_ratio": 0.5
  }
}
```

### Block Sparse Attention (BSA)

BSA reduces computation by sparsifying attention patterns, especially effective at high resolutions.

**When to Use BSA:**
- Generating 720p+ videos
- Limited VRAM
- Long video generation
- Batch processing

**BSA Parameters:**
- `block_size`: Larger blocks = more computation, better quality
- `sparse_ratio`: Higher ratio = less computation, potential quality loss

**Recommended BSA Settings:**
```json
{
  "bsa_params": {
    "block_size": 64,
    "sparse_ratio": 0.5
  }
}
```

---

## Performance Optimization

Maximize throughput and minimize latency.

### Torch Compilation

Enable `--enable_compile` for torch.compile optimization:

```bash
torchrun run_demo_text_to_video.py \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

**Benefits:**
- 20-30% speedup after warmup
- Automatic kernel fusion
- Memory optimization

**Trade-offs:**
- First run slower (compilation overhead)
- Increased disk usage for compiled kernels
- Debugging more difficult

### Quantization

Reduce model size and VRAM usage with quantization.

**INT8 Quantization (Avatar v1.5 only):**
```bash
torchrun run_demo_avatar_single_audio_to_video.py \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --use_int8 \
  --model_type avatar-v1.5
```

**Benefits:**
- 40% VRAM reduction
- Faster inference on INT8-optimized hardware
- Minimal quality loss (<1% perceptual)

**Requirements:**
- Avatar v1.5 model only
- CUDA 11.8+
- TensorRT-optimized GPUs recommended

### Distillation

Use distilled models for faster inference.

**Avatar v1.5 Distillation:**
```bash
torchrun run_demo_avatar_single_audio_to_video.py \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --use_distill \
  --model_type avatar-v1.5
```

**Benefits:**
- 8-step inference (vs 50 steps)
- 6x speedup
- Production-ready quality

**Quality Impact:**
- <2% perceptual quality loss
- Slightly less fine detail
- Recommended for most production use cases

### Batch Processing

Generate multiple videos efficiently.

**Batch Generation:**
```python
# Modify demo script to accept multiple prompts
prompts = [
    "A cat sitting on a sofa",
    "A dog running in a park",
    "A bird flying in the sky"
]

for prompt in prompts:
    pipeline.generate_t2v(prompt=prompt, ...)
```

**Multi-GPU Batching:**
- Use `context_parallel_size` for temporal parallelism
- Use data parallelism for batch dimension
- Combine for maximum throughput

---

## Memory Management

Optimize VRAM usage for your hardware.

### VRAM Optimization Strategies

1. **Reduce resolution**: 480p instead of 720p
2. **Fewer frames**: 33 frames instead of 49
3. **Enable INT8**: 40% VRAM reduction (Avatar v1.5)
4. **Use BSA**: Block sparse attention reduces memory
5. **Gradient checkpointing**: Trade compute for memory
6. **CPU offloading**: Move less-used components to CPU

### Memory Profiling

Monitor VRAM usage:

```python
import torch
print(f"VRAM allocated: {torch.cuda.memory_allocated() / 1e9:.2f} GB")
print(f"VRAM reserved: {torch.cuda.memory_reserved() / 1e9:.2f} GB")
```

### Out-of-Memory Solutions

**Immediate fixes:**
- Reduce resolution: `--height 480 --width 720`
- Reduce frames: `--num_frames 33`
- Enable INT8: `--use_int8`
- Use multi-GPU: `--context_parallel_size 2`

**Long-term solutions:**
- Upgrade GPU VRAM
- Use model quantization
- Implement gradient checkpointing
- Use CPU offloading for VAE

---

## Customization

Extend and customize LongCat-Video for specific use cases.

### Custom Prompts

Create prompt templates for consistent style:

```python
# prompt_templates.py
CINEMATIC_TEMPLATE = "Cinematic shot, {subject}, dramatic lighting, shallow depth of field, 4K quality"
ANIME_TEMPLATE = "Anime style, {subject}, vibrant colors, clean lines, Studio Ghibli inspired"

def generate_prompt(template, subject):
    return template.format(subject=subject)
```

### Custom Schedulers

Experiment with different sampling schedulers:

```python
from longcat_video.modules.scheduling_flow_match_euler_discrete import FlowMatchEulerDiscreteScheduler

# Custom scheduler configuration
scheduler = FlowMatchEulerDiscreteScheduler(
    num_train_timesteps=1000,
    shift=1.0,
    use_dynamic_shifting=False
)
```

### Custom Audio Processing

For avatar generation, customize audio preprocessing:

```python
from longcat_video.audio_process import get_audio_encoder

# Custom audio encoder configuration
audio_encoder = get_audio_encoder(
    model_type="whisper-large-v3",
    sample_rate=16000,
    feature_dim=768
)
```

### LoRA Fine-tuning

Add custom adapters for specific styles:

```python
from longcat_video.modules.lora_utils import create_lora_network

# Create LoRA network
lora_network = create_lora_network(
    model=dit,
    rank=8,
    alpha=16,
    target_modules=["to_q", "to_k", "to_v"]
)
```

---

## Production Deployment

Deploy LongCat-Video in production environments.

### Docker Containerization

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn8-runtime

RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt
COPY requirements_avatar.txt .
RUN pip install -r requirements_avatar.txt

COPY . /app
WORKDIR /app

CMD ["python", "run_demo_text_to_video.py"]
```

### API Server

Wrap generation in a REST API:

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class GenerationRequest(BaseModel):
    prompt: str
    num_frames: int = 49
    height: int = 480
    width: int = 720

@app.post("/generate")
async def generate_video(request: GenerationRequest):
    # Load pipeline
    pipeline = LongCatVideoPipeline(...)
    
    # Generate
    video = pipeline.generate_t2v(
        prompt=request.prompt,
        num_frames=request.num_frames,
        height=request.height,
        width=request.width
    )
    
    return {"status": "success", "video_path": "output.mp4"}
```

### Monitoring

Monitor generation performance:

```python
import time
import torch

def monitor_generation(pipeline, prompt):
    start_time = time.time()
    
    # Generate
    video = pipeline.generate_t2v(prompt=prompt)
    
    # Metrics
    generation_time = time.time() - start_time
    vram_used = torch.cuda.max_memory_allocated() / 1e9
    
    print(f"Generation time: {generation_time:.2f}s")
    print(f"VRAM used: {vram_used:.2f} GB")
    print(f"Throughput: {49 / generation_time:.2f} fps")
```

### Scaling Strategies

**Horizontal Scaling:**
- Deploy multiple GPU instances
- Use load balancer for request distribution
- Shared storage for models and outputs

**Vertical Scaling:**
- Use larger GPUs (A100, H100)
- Enable all optimizations (compile, INT8, distillation)
- Maximize batch size

**Hybrid Approach:**
- Use H100 for quality-critical generation
- Use A100 for batch processing
- Use smaller GPUs for development/testing

---

## Troubleshooting

Common issues and solutions.

### Generation Issues

**Problem: Blurry or low-quality output**
- Increase `--cfg_scale` (try 7.0 → 10.0)
- Increase `--num_inference_steps` (try 50 → 100)
- Check input image quality for I2V
- Verify model weights are correct

**Problem: Not following prompt**
- Make prompt more specific
- Add negative prompts
- Increase CFG scale
- Check prompt encoding (special characters)

**Problem: Temporal inconsistency**
- Reduce `--num_frames` for shorter videos
- Use reference frames for long videos
- Check for motion_scale too high (I2V)
- Enable video continuation with overlap

### Performance Issues

**Problem: Slow generation**
- Enable `--enable_compile`
- Use multi-GPU with context parallel
- Enable distillation (Avatar v1.5)
- Reduce resolution or frames

**Problem: Out of memory**
- Reduce resolution (480p → 360p)
- Reduce frames (49 → 33)
- Enable INT8 quantization
- Use multi-GPU
- Enable BSA attention

**Problem: CUDA errors**
- Check CUDA version compatibility
- Verify PyTorch CUDA version
- Update GPU drivers
- Check for sufficient GPU memory

### Avatar-Specific Issues

**Problem: Poor lip synchronization**
- Increase `--audio_cfg` (try 4.0 → 5.0)
- Use Avatar v1.5 (Whisper encoder)
- Check audio quality (clear speech)
- Verify audio sample rate (16kHz)

**Problem: Repetitive gestures**
- Set `--ref_img_index` to 30
- Increase `--mask_frame_range`
- Use calm style variant
- Check prompt for action cues

**Problem: Unnatural expressions**
- Use detailed prompts with expression cues
- Reduce `--audio_cfg` if too high
- Check for negative prompt conflicts
- Try different reference frames

---

## Best Practices

Production recommendations for reliable generation.

### Quality vs Speed Trade-offs

| Priority | Configuration |
|----------|---------------|
| Maximum Quality | FP16, 50 steps, no distillation, 720p |
| Balanced | FP16, distillation, 480p, 8 steps |
| Maximum Speed | INT8, distillation, 480p, 8 steps |
| Low VRAM | INT8, BSA, 360p, distillation |

### Prompt Engineering

- **Be specific**: Describe subject, action, environment, style
- **Include motion**: "walking slowly", "running fast", "floating"
- **Add camera info**: "close-up", "wide angle", "drone shot"
- **Specify lighting**: "dramatic lighting", "soft studio light"
- **Style cues**: "cinematic", "anime", "photorealistic"

### Workflow Optimization

1. **Prototype fast**: Use low resolution, few frames, distillation
2. **Iterate**: Adjust prompts and parameters based on results
3. **Scale up**: Increase resolution and frames for final output
4. **Batch process**: Generate multiple variations in parallel
5. **Quality check**: Review outputs before production use

### Resource Planning

**Development (Single GPU):**
- GPU: 24GB VRAM (RTX 4090)
- Resolution: 480p
- Use case: Prototyping, testing

**Production (Multi-GPU):**
- GPU: 4x 80GB (A100) or 2x 80GB (H100)
- Resolution: 720p+
- Use case: Batch generation, API service

**Edge/Low-Resource:**
- GPU: 16GB VRAM (RTX 4080)
- Resolution: 480p, INT8
- Use case: On-premise, limited budget

---

## Next Steps

- **Detailed specs**: Check `openspec/specs/` for comprehensive requirements
- **API integration**: Build custom services around LongCat-Video
- **Fine-tuning**: Customize models for specific domains
- **Research**: Explore technical reports for deep insights
