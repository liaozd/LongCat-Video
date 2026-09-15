# Generation Modes

Comprehensive guide to all video generation capabilities in LongCat-Video.

## Text-to-Video (T2V)

Generate videos from text descriptions.

### When to Use
- Creating content from scratch based on textual concepts
- Prototyping video ideas before production
- Generating diverse video variations from prompts

### Basic Usage

**Single GPU:**
```bash
torchrun run_demo_text_to_video.py --checkpoint_dir=./weights/LongCat-Video --enable_compile
```

**Multi GPU:**
```bash
torchrun --nproc_per_node=2 run_demo_text_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

### Key Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `--prompt` | (script default) | Text description of desired video |
| `--num_frames` | 49 | Number of frames to generate |
| `--height` / `--width` | 480 / 720 | Output resolution |
| `--cfg_scale` | 7.0 | Classifier-free guidance strength (higher = more prompt adherence) |
| `--num_inference_steps` | 50 | Denoising steps (higher = better quality, slower) |

### Prompt Engineering Tips

- **Be specific**: "A cat sitting on a red sofa" is better than "A cat"
- **Include motion cues**: "walking slowly", "running fast", "floating gently"
- **Add style descriptors**: "cinematic lighting", "anime style", "photorealistic"
- **Specify camera**: "close-up shot", "wide angle", "drone view"

### Common Issues

- **Blurry output**: Increase `--cfg_scale` or `--num_inference_steps`
- **Not following prompt**: Make prompt more specific, add negative prompts
- **Too slow**: Use multi-GPU or reduce resolution

---

## Image-to-Video (I2V)

Animate static images into videos.

### When to Use
- Bringing photos to life
- Creating consistent character animations
- Generating video from concept art

### Basic Usage

**Single GPU:**
```bash
torchrun run_demo_image_to_video.py --checkpoint_dir=./weights/LongCat-Video --enable_compile
```

**Multi GPU:**
```bash
torchrun --nproc_per_node=2 run_demo_image_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

### Key Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `--input_image` | (script default) | Path to input image |
| `--prompt` | (script default) | Optional text to guide animation |
| `--motion_scale` | 1.0 | Amount of motion to introduce |
| `--num_frames` | 49 | Duration of generated video |

### Best Practices

- **Use high-quality input images**: Sharp, well-lit images produce better results
- **Match prompt to image**: If image shows a person running, prompt should describe running motion
- **Start with low motion_scale**: Gradually increase if animation is too subtle
- **Consider image composition**: Wide shots allow more camera movement than close-ups

---

## Video Continuation (VC)

Extend existing videos seamlessly.

### When to Use
- Creating longer videos from short clips
- Generating consistent video sequences
- Building multi-scene narratives

### Basic Usage

**Single GPU:**
```bash
torchrun run_demo_video_continuation.py --checkpoint_dir=./weights/LongCat-Video --enable_compile
```

**Multi GPU:**
```bash
torchrun --nproc_per_node=2 run_demo_video_continuation.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

### Key Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `--input_video` | (script default) | Path to input video |
| `--prompt` | (script default) | Description of continuation |
| `--num_frames` | 49 | Frames to generate |
| `--overlap_frames` | 4 | Frames to overlap for smooth transition |

### Continuation Strategies

- **Maintain consistency**: Use prompts that describe the current scene's continuation
- **Plan transitions**: Use `--overlap_frames` to ensure smooth joins
- **Batch generation**: Generate multiple segments and stitch them for long videos

---

## Long Video Generation

Generate minutes-long videos without quality degradation.

### When to Use
- Creating extended content (news, tutorials, narratives)
- Generating consistent long-form videos
- Building video sequences with temporal coherence

### Basic Usage

**Single GPU:**
```bash
torchrun run_demo_long_video.py --checkpoint_dir=./weights/LongCat-Video --enable_compile
```

**Multi GPU:**
```bash
torchrun --nproc_per_node=2 run_demo_long_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

### Key Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `--num_segments` | 5 | Number of video segments to generate |
| `--num_frames_per_segment` | 49 | Frames per segment |
| `--ref_img_index` | 10 | Reference frame index for consistency |

### Long Video Tips

- **Use reference frames**: `--ref_img_index` helps maintain visual consistency across segments
- **Plan segment transitions**: Ensure prompts describe logical scene progressions
- **Monitor memory**: Long videos require more VRAM; use multi-GPU if needed

---

## Interactive Video Generation

Refine video generation interactively.

### When to Use
- Iterative video refinement
- Exploring multiple variations
- Fine-tuning specific video segments

### Basic Usage

**Single GPU:**
```bash
torchrun run_demo_interactive_video.py --checkpoint_dir=./weights/LongCat-Video --enable_compile
```

**Multi GPU:**
```bash
torchrun --nproc_per_node=2 run_demo_interactive_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video \
  --enable_compile
```

### Interactive Workflow

1. Generate initial video
2. Review output
3. Adjust prompt or parameters
4. Regenerate specific segments
5. Iterate until satisfied

---

## Avatar Single-Person

Audio-driven single-person video generation.

### When to Use
- Creating talking head videos
- Virtual presenters or anchors
- Lip-synced character animation

### Model Versions

**Avatar v1.5 (Recommended):**
- Uses Whisper-large-v3 audio encoder (better lip sync)
- Supports distillation (8-step fast inference)
- INT8 quantization for reduced VRAM
- Production-ready stability

**Avatar v1.0:**
- Uses Wav2Vec2 audio encoder
- Standard inference speed
- Higher VRAM requirements

### Basic Usage (v1.5)

**Audio-Text-to-Video:**
```bash
torchrun --nproc_per_node=2 run_demo_avatar_single_audio_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --stage_1=at2v \
  --input_json=assets/avatar/single_example_1.json \
  --use_distill \
  --model_type avatar-v1.5 \
  --use_int8
```

**Audio-Image-to-Video:**
```bash
torchrun --nproc_per_node=2 run_demo_avatar_single_audio_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --stage_1=ai2v \
  --input_json=assets/avatar/single_example_1.json \
  --use_distill \
  --model_type avatar-v1.5 \
  --use_int8
```

**Video Continuation:**
```bash
torchrun --nproc_per_node=2 run_demo_avatar_single_audio_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --stage_1=at2v \
  --input_json=assets/avatar/single_example_1.json \
  --num_segments=5 \
  --ref_img_index=10 \
  --mask_frame_range=3 \
  --use_distill \
  --model_type avatar-v1.5 \
  --use_int8
```

### Input JSON Format

```json
{
  "prompt": "A young woman with long black hair is speaking and smiling, wearing a white blouse, sitting in a bright café",
  "cond_image": "path/to/reference_image.png",
  "cond_audio": {
    "person1": "path/to/audio.mp3"
  }
}
```

### Key Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `--audio_cfg` | 4.0 | Audio guidance strength (3-5 optimal for lip sync) |
| `--ref_img_index` | 10 | Reference frame for consistency (0-24 for consistency, 30 to reduce repetition) |
| `--mask_frame_range` | 3 | Frame range for masking (higher reduces repetition but may introduce artifacts) |
| `--resolution` | 480 | Output resolution (480 or 720) |
| `--use_distill` | false | Enable distillation (required for v1.5, faster inference) |
| `--use_int8` | false | Enable INT8 quantization (reduces VRAM, v1.5 only) |

### Avatar Tips

**Lip Synchronization:**
- Set `--audio_cfg` between 3-5 for optimal sync
- Higher values improve sync but may reduce naturalness

**Prompt Enhancement:**
- Use detailed prompts with character appearance, actions, and scene context
- Include verbal cues like "speaking", "talking" for natural lip movements

**Reduce Repetitive Actions:**
- Set `--ref_img_index` to 30 to reduce repeated gestures
- Increase `--mask_frame_range` (but avoid excessive values)

**Calm Style (News Anchor):**
- Use `run_demo_avatar_single_calm.py` for calm, professional presentation style
- Removes negative prompts that suppress quiet scenes
- Explicitly suppresses exaggerated expressions

---

## Avatar Multi-Person

Audio-driven multi-person conversation video generation.

### When to Use
- Creating dialogue videos
- Multi-character interactions
- Conversation scenarios

### Basic Usage (v1.5)

**Audio-Image-to-Video:**
```bash
torchrun --nproc_per_node=2 run_demo_avatar_multi_audio_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --input_json=assets/avatar/multi_example_1.json \
  --use_distill \
  --model_type avatar-v1.5 \
  --use_int8
```

**Video Continuation:**
```bash
torchrun --nproc_per_node=2 run_demo_avatar_multi_audio_to_video.py \
  --context_parallel_size=2 \
  --checkpoint_dir=./weights/LongCat-Video-Avatar-1.5 \
  --input_json=assets/avatar/multi_example_1.json \
  --num_segments=5 \
  --ref_img_index=10 \
  --mask_frame_range=3 \
  --use_distill \
  --model_type avatar-v1.5 \
  --use_int8
```

### Input JSON Format

```json
{
  "prompt": "Static camera, In a professional recording studio, two people stand facing each other, both wearing large headphones. They are speaking clearly into a large condenser microphone suspended between them.",
  "cond_image": "path/to/reference_image.png",
  "cond_audio": {
    "person1": "path/to/person1_audio.wav",
    "person2": "path/to/person2_audio.wav"
  },
  "audio_type": "para"
}
```

### Audio Modes

**Merge Mode (`--audio_type para`):**
- Requires two audio clips of equal length
- Resulting audio is sum of both clips
- Best for simultaneous speaking or overlapping dialogue

**Concatenation Mode (`--audio_type add`):**
- Does not require equal-length inputs
- Audio clips are concatenated with silence padding
- Default: person1 speaks first, then person2
- Best for turn-taking conversations

### Multi-Person Tips

- **Audio separation**: Ensure clear separation between speakers in reference image
- **Timing**: Use concatenation mode for natural conversation flow
- **Reference image**: Include both characters clearly visible
- **Prompt**: Describe interaction dynamics (facing each other, gestures, etc.)

---

## Streamlit Web Interface

Interactive web UI for all generation modes.

### Usage

```bash
streamlit run ./run_streamlit.py --server.fileWatcherType none --server.headless=false
```

### Features

- Browser-based interface
- Real-time parameter adjustment
- Visual preview of results
- Support for all generation modes

---

## Choosing the Right Mode

| Use Case | Recommended Mode |
|----------|------------------|
| Create video from description | Text-to-Video |
| Animate a photo | Image-to-Video |
| Extend existing video | Video Continuation |
| Generate long-form content | Long Video |
| Talking head video | Avatar Single-Person |
| Dialogue/conversation | Avatar Multi-Person |
| Interactive refinement | Interactive Video |
| No-code exploration | Streamlit |

## Next Steps

- **Advanced configuration**: See [Advanced Configuration](advanced-configuration.md)
- **Infrastructure setup**: Multi-GPU, attention optimization
- **Detailed specs**: Check `openspec/specs/` for comprehensive requirements
