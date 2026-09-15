# Spec: Avatar Single-Person Generation

## Purpose
Enable users to generate audio-driven single-person video content using LongCat-Video-Avatar models, supporting both v1.0 (Wav2Vec2) and v1.5 (Whisper) variants with different optimization options.

## ADDED Requirements

### Requirement: Generate avatar video from audio
The system must generate a video of a person speaking based on provided audio and reference image.

#### Scenario: Audio-text-to-video generation
- **WHEN** a user provides audio, a text prompt, and runs the avatar generation command
- **THEN** the system generates a video showing a person speaking according to the audio
- **AND** the person's lip movements synchronize with the audio
- **AND** the visual appearance matches the reference image
- **AND** the scene follows the text prompt description
- **AND** the output is saved as an MP4 file

#### Scenario: Audio-image-to-video generation
- **WHEN** a user provides audio and a reference image (without text prompt)
- **THEN** the system generates a video showing the person in the reference image speaking
- **AND** lip movements synchronize with the audio
- **AND** maintains the reference image's visual characteristics
- **AND** the output is saved as an MP4 file

#### Scenario: Avatar video continuation
- **WHEN** a user enables video continuation with multiple segments
- **THEN** the system generates multiple video segments extending the avatar video
- **AND** maintains lip synchronization across all segments
- **AND** ensures temporal consistency and stability throughout the long video
- **AND** creates smooth transitions between segments

#### Scenario: Multi-GPU avatar generation
- **WHEN** a user enables context parallel with multiple GPUs
- **THEN** the system distributes the generation workload across GPUs
- **AND** generates the avatar video faster than single-GPU mode
- **AND** maintains lip sync quality equivalent to single-GPU output

### Requirement: Support multiple model versions
The system must support both Avatar v1.0 and v1.5 models with their respective features.

#### Scenario: Use Avatar v1.5 (recommended)
- **WHEN** a user specifies model_type as avatar-v1.5
- **THEN** the system uses the Whisper-large-v3 audio encoder for better lip synchronization
- **AND** supports distillation mode for faster inference
- **AND** supports INT8 quantization for reduced VRAM usage
- **AND** achieves 20-30% better lip sync accuracy than v1.0

#### Scenario: Use Avatar v1.0 (legacy)
- **WHEN** a user specifies model_type as avatar-v1.0
- **THEN** the system uses the Wav2Vec2 audio encoder
- **AND** uses standard inference (50 steps)
- **AND** does not support INT8 quantization
- **AND** requires more VRAM than v1.5

#### Scenario: Distillation mode (v1.5)
- **WHEN** a user enables use_distill with Avatar v1.5
- **THEN** the system uses 8-step distillation inference instead of 50 steps
- **AND** achieves 6x speedup compared to standard inference
- **AND** maintains production-ready quality (<2% perceptual loss)
- **AND** is required for v1.5 model usage

#### Scenario: INT8 quantization (v1.5)
- **WHEN** a user enables use_int8 with Avatar v1.5
- **THEN** the system loads the INT8 quantized DiT model
- **AND** reduces VRAM usage by approximately 40%
- **AND** maintains minimal quality loss (<1% perceptual)
- **AND** is only supported with Avatar v1.5

### Requirement: Control lip synchronization
The system must allow users to control the accuracy of lip synchronization with audio.

#### Scenario: Adjust audio CFG strength
- **WHEN** a user modifies the audio_cfg parameter
- **THEN** higher audio_cfg values (3-5) produce better lip synchronization
- **AND** values outside this range may reduce naturalness or sync quality
- **AND** the system recommends optimal range (3-5) for best results

#### Scenario: Handle different audio quality
- **WHEN** users provide audio with varying quality (clear speech, background noise, different sample rates)
- **THEN** the system adapts to achieve the best possible lip synchronization
- **AND** may warn about poor audio quality affecting sync accuracy
- **AND** recommends 16kHz sample rate for optimal results

### Requirement: Control temporal consistency
The system must provide options to maintain visual consistency and reduce repetitive actions.

#### Scenario: Reference frame selection
- **WHEN** a user specifies ref_img_index parameter
- **THEN** values between 0-24 ensure better consistency with reference image
- **AND** value of 30 helps reduce repetitive gestures
- **AND** the system uses the specified frame as a consistency reference

#### Scenario: Mask frame range adjustment
- **WHEN** a user modifies mask_frame_range parameter
- **THEN** higher values help mitigate repetitive actions
- **AND** excessively high values may introduce visual artifacts
- **AND** the system recommends balanced values (default 3) for optimal results

#### Scenario: Calm style variant
- **WHEN** a user uses the calm avatar script (run_demo_avatar_single_calm.py)
- **THEN** the system removes negative prompts that suppress quiet scenes
- **AND** explicitly suppresses exaggerated facial expressions and dramatic gestures
- **AND** generates calm, professional presentation style (e.g., news anchor)
- **AND** allows negative_prompt override via input JSON

### Requirement: Support various input formats
The system must accept common audio and image file formats.

#### Scenario: Process standard audio formats
- **WHEN** a user provides audio in MP3, WAV, or FLAC format
- **THEN** the system successfully loads and processes the audio
- **AND** generates avatar video without format-related errors

#### Scenario: Process standard image formats
- **WHEN** a user provides reference images in PNG, JPEG, or WebP format
- **THEN** the system successfully loads and processes the image
- **AND** generates avatar video without format-related errors

#### Scenario: JSON configuration input
- **WHEN** a user provides a JSON file with prompt, image, and audio paths
- **THEN** the system parses the JSON and extracts all required inputs
- **AND** supports optional fields like negative_prompt for customization
- **AND** validates input paths before generation

### Requirement: Control output quality
The system must allow users to control video resolution and quality parameters.

#### Scenario: Adjust output resolution
- **WHEN** a user specifies resolution parameter (480 or 720)
- **THEN** the system generates video at the specified resolution
- **AND** maintains aspect ratio of the reference image
- **AND** higher resolution requires more VRAM and computation time

#### Scenario: Control generation quality
- **WHEN** a user increases the number of inference steps (non-distillation mode)
- **THEN** the system produces higher quality video with more detail
- **AND** generation time increases linearly with step count
- **AND** distillation mode overrides this with fixed 8 steps

### Requirement: Optimize generation performance
The system must provide options to optimize generation speed and resource usage.

#### Scenario: Enable torch compilation
- **WHEN** a user enables the compile flag
- **THEN** the system uses torch.compile for kernel fusion and optimization
- **AND** achieves 20-30% speedup after initial compilation
- **AND** compilation overhead occurs only on first run

#### Scenario: Context parallel scaling
- **WHEN** a user configures context parallel with N GPUs
- **THEN** the system splits temporal computation across N GPUs
- **AND** achieves near-linear speedup for N <= 4
- **AND** requires sufficient GPU memory per device

#### Scenario: Distillation for speed
- **WHEN** a user enables distillation mode with Avatar v1.5
- **THEN** the system uses 8-step inference for 6x speedup
- **AND** maintains production-ready quality
- **AND** is recommended for most production use cases

### Requirement: Handle generation errors gracefully
The system must provide clear error messages and recovery guidance.

#### Scenario: Invalid audio file
- **WHEN** a user provides an audio file that cannot be loaded
- **THEN** the system reports a clear audio loading error
- **AND** suggests checking the file format and integrity

#### Scenario: Poor lip synchronization
- **WHEN** generated video has poor lip sync with audio
- **THEN** the system may suggest increasing audio_cfg parameter
- **AND** recommends using Avatar v1.5 for better sync
- **AND** suggests checking audio quality and clarity

#### Scenario: Repetitive gestures
- **WHEN** avatar exhibits repetitive unnatural movements
- **THEN** the system may suggest adjusting ref_img_index to 30
- **AND** recommends increasing mask_frame_range
- **AND** suggests using calm style variant for professional presentation

#### Scenario: Out of memory error
- **WHEN** GPU memory is insufficient for the requested configuration
- **THEN** the system reports a clear out-of-memory error
- **AND** suggests enabling INT8 quantization (v1.5 only)
- **AND** recommends reducing resolution or enabling multi-GPU mode

## MODIFIED Requirements
None - this is a new specification.

## DELETED Requirements
None - this is a new specification.

## Progressive Disclosure Layers

### Layer 1: Essential (5 minutes)
- Single command to generate avatar from audio and image
- Use Avatar v1.5 with distillation and INT8 for best performance
- Default parameters work for most use cases
- Output: MP4 video file with lip-synced avatar

### Layer 2: Core Features (30 minutes)
- Lip synchronization control (audio_cfg)
- Temporal consistency (ref_img_index, mask_frame_range)
- Model version selection (v1.0 vs v1.5)
- Prompt enhancement for better results
- Calm style variant for professional presentation
- Multi-GPU setup for faster generation

### Layer 3: Advanced (hours)
- Custom negative prompts
- Advanced audio preprocessing
- Integration with custom audio pipelines
- Performance profiling and optimization
- Production deployment considerations
