# Spec: Infrastructure

## Purpose
Provide system-level capabilities for performance optimization, scalability, and hardware adaptation across all LongCat-Video generation modes.

## ADDED Requirements

### Requirement: Multi-GPU context parallel support
The system must support distributing generation workload across multiple GPUs using context parallelism.

#### Scenario: Basic context parallel setup
- **WHEN** a user configures context_parallel_size to N
- **THEN** the system splits temporal computation across N GPUs
- **AND** achieves near-linear speedup for N <= 4
- **AND** requires sufficient GPU memory per device
- **AND** maintains output quality equivalent to single-GPU mode

#### Scenario: Context parallel with different GPU counts
- **WHEN** a user configures context parallel with 2, 4, or 8 GPUs
- **THEN** the system automatically adapts the workload distribution
- **AND** optimizes communication patterns for the specific GPU count
- **AND** provides clear guidance on recommended GPU configurations

#### Scenario: Multi-node distributed setup
- **WHEN** a user configures multi-node distributed training/inference
- **THEN** the system supports PyTorch distributed communication across nodes
- **AND** handles master-worker coordination automatically
- **AND** provides clear error messages for network or configuration issues

### Requirement: Attention mechanism selection
The system must support multiple attention computation backends for different hardware and performance requirements.

#### Scenario: FlashAttention-2 configuration
- **WHEN** a user configures attention_type as flash_attn_2
- **THEN** the system uses FlashAttention-2 for efficient attention computation
- **AND** requires CUDA 11.8+ and Ampere+ architecture GPUs
- **AND** provides fast computation with moderate VRAM usage
- **AND** is the default attention mechanism

#### Scenario: FlashAttention-3 configuration
- **WHEN** a user configures attention_type as flash_attn_3
- **THEN** the system uses FlashAttention-3 for maximum performance
- **AND** requires Hopper architecture GPUs (H100+)
- **AND** achieves fastest computation with lowest VRAM usage
- **AND** provides best performance on supported hardware

#### Scenario: xFormers configuration
- **WHEN** a user configures attention_type as xformers
- **THEN** the system uses xFormers memory-efficient attention
- **AND** requires CUDA 11.3+
- **AND** provides moderate speed with low VRAM usage
- **AND** is suitable for older GPU architectures

#### Scenario: Block Sparse Attention (BSA) configuration
- **WHEN** a user enables BSA with enable_bsa: true
- **THEN** the system uses block sparse attention for reduced computation
- **AND** supports configurable block_size and sparse_ratio parameters
- **AND** achieves significant VRAM reduction at high resolutions
- **AND** is particularly effective for 720p+ video generation

#### Scenario: BSA parameter tuning
- **WHEN** a user adjusts BSA parameters (block_size, sparse_ratio)
- **THEN** larger block_size increases computation and quality
- **AND** higher sparse_ratio reduces computation but may affect quality
- **AND** the system provides recommended default values

### Requirement: Torch compilation optimization
The system must support torch.compile for automatic kernel fusion and optimization.

#### Scenario: Enable torch compilation
- **WHEN** a user enables the enable_compile flag
- **THEN** the system uses torch.compile for automatic optimization
- **AND** achieves 20-30% speedup after initial compilation
- **AND** compilation overhead occurs only on first run
- **AND** compiled kernels are cached for subsequent runs

#### Scenario: Compilation error handling
- **WHEN** torch compilation encounters errors
- **THEN** the system provides clear error messages
- **AND** falls back to non-compiled execution
- **AND** suggests checking CUDA compatibility and PyTorch version

### Requirement: Model quantization support
The system must support INT8 quantization for reduced VRAM usage (Avatar v1.5 only).

#### Scenario: INT8 quantization enablement
- **WHEN** a user enables use_int8 with Avatar v1.5
- **THEN** the system loads the INT8 quantized DiT model
- **AND** reduces VRAM usage by approximately 40%
- **AND** maintains minimal quality loss (<1% perceptual)
- **AND** is only supported with Avatar v1.5 model

#### Scenario: Quantization error handling
- **WHEN** a user attempts INT8 quantization with unsupported model
- **THEN** the system reports that INT8 is only supported with Avatar v1.5
- **AND** suggests using FP16 or upgrading to Avatar v1.5

### Requirement: Distillation mode support
The system must support step distillation for faster inference (Avatar v1.5 only).

#### Scenario: Enable distillation mode
- **WHEN** a user enables use_distill with Avatar v1.5
- **THEN** the system uses 8-step distillation inference instead of 50 steps
- **AND** achieves 6x speedup compared to standard inference
- **AND** maintains production-ready quality (<2% perceptual loss)
- **AND** is required for Avatar v1.5 model usage

#### Scenario: Distillation vs quality trade-off
- **WHEN** a user chooses between distillation and standard inference
- **THEN** the system provides clear guidance on quality vs speed trade-offs
- **AND** recommends distillation for most production use cases
- **AND** suggests standard inference for maximum quality requirements

### Requirement: Memory management
The system must provide effective memory management for various hardware configurations.

#### Scenario: VRAM optimization
- **WHEN** GPU memory is limited
- **THEN** the system supports multiple optimization strategies
- **AND** provides recommendations for reducing memory usage
- **AND** includes options like resolution reduction, INT8 quantization, BSA

#### Scenario: Gradient checkpointing
- **WHEN** a user enables gradient checkpointing
- **THEN** the system trades computation for memory
- **AND** reduces VRAM usage at the cost of increased computation time
- **AND** is suitable for memory-constrained environments

#### Scenario: CPU offloading
- **WHEN** a user enables CPU offloading for specific components
- **THEN** the system moves less-used components to CPU memory
- **AND** reduces GPU VRAM usage
- **AND** may increase overall generation time

### Requirement: Performance monitoring
The system must provide tools for monitoring and profiling generation performance.

#### Scenario: VRAM usage monitoring
- **WHEN** a user wants to monitor GPU memory usage
- **THEN** the system provides real-time VRAM allocation and reservation metrics
- **AND** reports peak memory usage during generation
- **AND** helps identify memory bottlenecks

#### Scenario: Generation timing metrics
- **WHEN** a user wants to measure generation performance
- **THEN** the system provides timing metrics for each generation stage
- **AND** reports total generation time and throughput (fps)
- **AND** helps identify performance bottlenecks

#### Scenario: Performance profiling
- **WHEN** a user enables detailed profiling
- **THEN** the system provides per-component timing breakdown
- **AND** identifies slow operations for optimization
- **AND** suggests optimization strategies based on profiling data

### Requirement: Hardware compatibility
The system must support various GPU architectures and CUDA versions.

#### Scenario: CUDA version compatibility
- **WHEN** a user runs the system with different CUDA versions
- **THEN** the system checks CUDA compatibility before execution
- **AND** provides clear error messages for incompatible versions
- **AND** suggests compatible CUDA versions for each feature

#### Scenario: GPU architecture detection
- **WHEN** the system starts on different GPU architectures
- **THEN** the system automatically detects the GPU architecture
- **AND** selects appropriate attention mechanisms (FlashAttn2/3, xFormers)
- **AND** provides recommendations for optimal configuration

#### Scenario: Minimum hardware requirements
- **WHEN** a user runs on minimum-spec hardware
- **THEN** the system provides clear guidance on supported features
- **AND** suggests configuration adjustments for feasible operation
- **AND** warns about quality or speed limitations

### Requirement: Configuration management
The system must provide flexible configuration options for various deployment scenarios.

#### Scenario: Model configuration editing
- **WHEN** a user wants to modify model configuration
- **THEN** the system supports editing config.json files
- **AND** validates configuration changes before application
- **AND** provides clear error messages for invalid configurations

#### Scenario: Environment variable configuration
- **WHEN** a user prefers environment variable configuration
- **THEN** the system supports key configuration via environment variables
- **AND** provides clear documentation of supported variables
- **AND** respects environment variable overrides

#### Scenario: Command-line argument precedence
- **WHEN** a user specifies conflicting configurations (config file, env vars, CLI args)
- **THEN** the system follows a clear precedence order (CLI > env vars > config file)
- **AND** provides warnings when configuration overrides occur

### Requirement: Error handling and diagnostics
The system must provide comprehensive error handling and diagnostic information.

#### Scenario: CUDA error reporting
- **WHEN** a CUDA error occurs during generation
- **THEN** the system provides clear, actionable error messages
- **AND** suggests common fixes (driver update, memory reduction, version check)
- **AND** includes diagnostic information for troubleshooting

#### Scenario: Model loading error handling
- **WHEN** model loading fails
- **THEN** the system reports specific loading failure reasons
- **AND** suggests checking file paths, integrity, and compatibility
- **AND** provides guidance on model download and verification

#### Scenario: Distributed system errors
- **WHEN** distributed setup encounters errors
- **THEN** the system reports which node/process failed
- **AND** provides network and configuration diagnostic information
- **AND** suggests common distributed setup fixes

## MODIFIED Requirements
None - this is a new specification.

## DELETED Requirements
None - this is a new specification.

## Progressive Disclosure Layers

### Layer 1: Essential (5 minutes)
- Basic multi-GPU setup with context parallel
- Default attention mechanism (FlashAttention-2)
- Enable torch compilation for speedup
- Default configuration works for most hardware

### Layer 2: Core Features (30 minutes)
- Attention mechanism selection (FlashAttn2/3, xFormers, BSA)
- Model quantization (INT8 for v1.5)
- Distillation mode for faster inference
- Memory management strategies
- Hardware compatibility guidance

### Layer 3: Advanced (hours)
- Multi-node distributed setup
- Custom attention implementations
- Performance profiling and optimization
- Advanced memory management (gradient checkpointing, CPU offloading)
- Production deployment and scaling
