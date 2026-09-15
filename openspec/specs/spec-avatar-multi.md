# Spec: Avatar Multi-Person Generation

## Purpose
Enable users to generate audio-driven multi-person conversation video content using LongCat-Video-Avatar models, supporting dual audio streams with different mixing modes.

## ADDED Requirements

### Requirement: Generate multi-person avatar video from dual audio
The system must generate a video showing two people speaking based on provided dual audio streams and reference image.

#### Scenario: Dual audio-image-to-video generation
- **WHEN** a user provides two audio streams (person1, person2), a reference image, and runs the multi-avatar generation command
- **THEN** the system generates a video showing both people speaking according to their respective audio
- **AND** each person's lip movements synchronize with their assigned audio stream
- **AND** the visual appearance matches the reference image for both characters
- **AND** the scene follows the text prompt description
- **AND** the output is saved as an MP4 file

#### Scenario: Multi-avatar video continuation
- **WHEN** a user enables video continuation with multiple segments
- **THEN** the system generates multiple video segments extending the multi-avatar video
- **AND** maintains lip synchronization for both characters across all segments
- **AND** ensures temporal consistency and interaction dynamics throughout the long video
- **AND** creates smooth transitions between segments

#### Scenario: Multi-GPU multi-avatar generation
- **WHEN** a user enables context parallel with multiple GPUs
- **THEN** the system distributes the generation workload across GPUs
- **AND** generates the multi-avatar video faster than single-GPU mode
- **AND** maintains lip sync quality for both characters equivalent to single-GPU output

### Requirement: Support audio mixing modes
The system must support different modes for combining dual audio streams.

#### Scenario: Merge mode (parallel)
- **WHEN** a user sets audio_type to "para" (parallel/merge)
- **THEN** the system requires both audio clips to have equal length
- **AND** the resulting audio is the sum of both clips
- **AND** both characters speak simultaneously in the generated video
- **AND** is suitable for overlapping dialogue or simultaneous speaking

#### Scenario: Concatenation mode (additive)
- **WHEN** a user sets audio_type to "add" (additive/concatenation)
- **THEN** the system does not require equal-length audio inputs
- **AND** the resulting audio is formed by sequentially concatenating both clips
- **AND** adds silence padding for any gaps between clips
- **AND** by default, person1 speaks first, then person2 speaks afterward
- **AND** is suitable for turn-taking conversations

#### Scenario: Custom speaking order
- **WHEN** a user wants to change the default speaking order in concatenation mode
- **THEN** the system supports reordering the audio clips in the JSON configuration
- **AND** respects the specified speaking order in the generated video

### Requirement: Control character interaction
The system must allow users to control the interaction dynamics between multiple characters.

#### Scenario: Reference image with multiple characters
- **WHEN** a user provides a reference image showing two people
- **THEN** the system identifies and animates both characters according to their audio
- **AND** maintains clear visual separation between characters
- **AND** ensures each character's movements correspond to their assigned audio

#### Scenario: Prompt-based interaction guidance
- **WHEN** a user provides a text prompt describing the interaction (e.g., "facing each other", "looking at each other affectionately")
- **THEN** the system generates appropriate interaction dynamics matching the description
- **AND** characters exhibit natural interaction behaviors (head turns, gestures)
- **AND** maintains logical consistency in the interaction

#### Scenario: Audio-driven interaction timing
- **WHEN** dual audio streams have different speaking patterns
- **THEN** the system synchronizes character movements with their respective audio timing
- **AND** characters react naturally to each other's speech
- **AND** maintains realistic conversation flow

### Requirement: Support model versions and optimizations
The system must support both Avatar v1.0 and v1.5 models with their respective features for multi-person generation.

#### Scenario: Use Avatar v1.5 (recommended)
- **WHEN** a user specifies model_type as avatar-v1.5 for multi-avatar generation
- **THEN** the system uses the Whisper-large-v3 audio encoder for better lip synchronization for both characters
- **AND** supports distillation mode for faster inference
- **AND** supports INT8 quantization for reduced VRAM usage
- **AND** achieves better lip sync accuracy for both speakers

#### Scenario: Distillation mode (v1.5)
- **WHEN** a user enables use_distill with Avatar v1.5 for multi-avatar
- **THEN** the system uses 8-step distillation inference instead of 50 steps
- **AND** achieves 6x speedup compared to standard inference
- **AND** maintains production-ready quality for both characters
- **AND** is required for v1.5 model usage

#### Scenario: INT8 quantization (v1.5)
- **WHEN** a user enables use_int8 with Avatar v1.5 for multi-avatar
- **THEN** the system loads the INT8 quantized DiT model
- **AND** reduces VRAM usage by approximately 40%
- **AND** maintains minimal quality loss for both characters
- **AND** is only supported with Avatar v1.5

### Requirement: Control lip synchronization for multiple speakers
The system must allow users to control the accuracy of lip synchronization for each character.

#### Scenario: Adjust audio CFG strength
- **WHEN** a user modifies the audio_cfg parameter
- **THEN** higher audio_cfg values (3-5) produce better lip synchronization for both characters
- **AND** values outside this range may reduce naturalness or sync quality
- **AND** the system recommends optimal range (3-5) for best results

#### Scenario: Handle different audio quality per speaker
- **WHEN** users provide audio with varying quality for each speaker
- **THEN** the system adapts to achieve the best possible lip synchronization for each
- **AND** may warn about poor audio quality affecting sync accuracy for specific speakers
- **AND** recommends consistent audio quality for optimal results

### Requirement: Control temporal consistency
The system must provide options to maintain visual consistency and reduce repetitive actions for multiple characters.

#### Scenario: Reference frame selection
- **WHEN** a user specifies ref_img_index parameter
- **THEN** values between 0-24 ensure better consistency with reference image for both characters
- **AND** value of 30 helps reduce repetitive gestures for both
- **AND** the system uses the specified frame as a consistency reference

#### Scenario: Mask frame range adjustment
- **WHEN** a user modifies mask_frame_range parameter
- **THEN** higher values help mitigate repetitive actions for both characters
- **AND** excessively high values may introduce visual artifacts
- **AND** the system recommends balanced values (default 3) for optimal results

### Requirement: Support various input formats
The system must accept common audio and image file formats for multi-person inputs.

#### Scenario: Process standard audio formats for multiple speakers
- **WHEN** a user provides audio in MP3, WAV, or FLAC format for both speakers
- **THEN** the system successfully loads and processes both audio streams
- **AND** generates multi-avatar video without format-related errors

#### Scenario: Process standard image formats
- **WHEN** a user provides reference images in PNG, JPEG, or WebP format
- **THEN** the system successfully loads and processes the image
- **AND** generates multi-avatar video without format-related errors

#### Scenario: JSON configuration input
- **WHEN** a user provides a JSON file with prompt, image, and dual audio paths
- **THEN** the system parses the JSON and extracts all required inputs
- **AND** supports audio_type field to specify mixing mode
- **AND** validates input paths before generation

### Requirement: Control output quality
The system must allow users to control video resolution and quality parameters for multi-person generation.

#### Scenario: Adjust output resolution
- **WHEN** a user specifies resolution parameter (480 or 720)
- **THEN** the system generates video at the specified resolution
- **AND** maintains aspect ratio of the reference image
- **AND** higher resolution requires more VRAM and computation time

#### Scenario: Control generation quality
- **WHEN** a user increases the number of inference steps (non-distillation mode)
- **THEN** the system produces higher quality video with more detail for both characters
- **AND** generation time increases linearly with step count
- **AND** distillation mode overrides this with fixed 8 steps

### Requirement: Optimize generation performance
The system must provide options to optimize generation speed and resource usage for multi-person scenarios.

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
- **AND** maintains production-ready quality for both characters
- **AND** is recommended for most production use cases

### Requirement: Handle generation errors gracefully
The system must provide clear error messages and recovery guidance for multi-person scenarios.

#### Scenario: Invalid audio file for one speaker
- **WHEN** a user provides an audio file for one speaker that cannot be loaded
- **THEN** the system reports a clear audio loading error for the specific speaker
- **AND** suggests checking the file format and integrity

#### Scenario: Mismatched audio lengths in merge mode
- **WHEN** a user uses merge mode (para) with unequal audio lengths
- **THEN** the system reports an error requiring equal-length audio clips
- **AND** suggests using concatenation mode (add) or trimming audio to match lengths

#### Scenario: Poor lip synchronization for one character
- **WHEN** generated video has poor lip sync for one character
- **THEN** the system may suggest increasing audio_cfg parameter
- **AND** recommends using Avatar v1.5 for better sync
- **AND** suggests checking audio quality and clarity for that specific speaker

#### Scenario: Character interaction issues
- **WHEN** characters exhibit unnatural interaction or lack of coordination
- **THEN** the system may suggest adjusting the prompt to better describe interaction dynamics
- **AND** recommends ensuring reference image clearly shows both characters
- **AND** suggests checking audio timing for natural conversation flow

#### Scenario: Out of memory error
- **WHEN** GPU memory is insufficient for multi-avatar generation
- **THEN** the system reports a clear out-of-memory error
- **AND** suggests enabling INT8 quantization (v1.5 only)
- **AND** recommends reducing resolution or enabling multi-GPU mode

## MODIFIED Requirements
None - this is a new specification.

## DELETED Requirements
None - this is a new specification.

## Progressive Disclosure Layers

### Layer 1: Essential (5 minutes)
- Single command to generate multi-avatar video from dual audio and image
- Use Avatar v1.5 with distillation and INT8 for best performance
- Choose audio mixing mode (merge vs concatenation)
- Default parameters work for most use cases
- Output: MP4 video file with two lip-synced characters

### Layer 2: Core Features (30 minutes)
- Audio mixing modes (merge/concatenation)
- Lip synchronization control (audio_cfg)
- Temporal consistency (ref_img_index, mask_frame_range)
- Character interaction guidance via prompts
- Model version selection (v1.0 vs v1.5)
- Multi-GPU setup for faster generation

### Layer 3: Advanced (hours)
- Custom speaking order in concatenation mode
- Advanced audio preprocessing per speaker
- Integration with custom audio pipelines
- Complex scene layouts and interactions
- Performance profiling and optimization
- Production deployment considerations
