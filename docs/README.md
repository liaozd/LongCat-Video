# LongCat-Video Documentation

This directory contains progressive disclosure documentation for LongCat-Video, organized by learning layers.

## Documentation Structure

### Progressive Disclosure Layers

The documentation is organized into three layers, designed for different time commitments:

#### Layer 1: Quick Start (5 minutes)
**File:** [quick-start.md](quick-start.md)
- Get started in under 5 minutes
- Installation and model download
- One-command examples for T2V and Avatar
- Essential troubleshooting

#### Layer 2: Generation Modes (30 minutes)
**File:** [generation-modes.md](generation-modes.md)
- Comprehensive guide to all generation capabilities
- Text-to-Video, Image-to-Video, Video Continuation
- Long Video and Interactive Video
- Avatar Single-Person and Multi-Person
- Streamlit web interface
- Parameter guidance and best practices

#### Layer 3: Advanced Configuration (hours)
**File:** [advanced-configuration.md](advanced-configuration.md)
- Multi-GPU setup and context parallel
- Model variants and version comparison
- Attention mechanisms (FlashAttn2/3, xFormers, BSA)
- Performance optimization strategies
- Memory management
- Production deployment
- Customization and integration

## OpenSpec Specifications

Detailed technical specifications are available in `../openspec/specs/`:

- [spec-text-to-video](../openspec/specs/spec-text-to-video.md) - Text-to-video generation requirements
- [spec-image-to-video](../openspec/specs/spec-image-to-video.md) - Image-to-video generation requirements
- [spec-video-continuation](../openspec/specs/spec-video-continuation.md) - Video continuation and long video requirements
- [spec-avatar-single](../openspec/specs/spec-avatar-single.md) - Single-person avatar generation requirements
- [spec-avatar-multi](../openspec/specs/spec-avatar-multi.md) - Multi-person avatar generation requirements
- [spec-infrastructure](../openspec/specs/spec-infrastructure.md) - Infrastructure and system capabilities

Each spec includes:
- Purpose and requirements
- Detailed scenarios with WHEN/THEN conditions
- Progressive disclosure layers
- Error handling and edge cases

## Navigation Guide

### For New Users
1. Start with [quick-start.md](quick-start.md) to get your first video running
2. Explore [generation-modes.md](generation-modes.md) to understand all capabilities
3. Reference [advanced-configuration.md](advanced-configuration.md) when optimizing for production

### For Developers
1. Review OpenSpec specs in `../openspec/specs/` for detailed requirements
2. Use [advanced-configuration.md](advanced-configuration.md) for deployment guidance
3. Reference specific specs when implementing features

### For Researchers
1. Review all OpenSpec specs for comprehensive capability documentation
2. Use [generation-modes.md](generation-modes.md) for usage patterns
3. Check [advanced-configuration.md](advanced-configuration.md) for optimization strategies

## Documentation Philosophy

This documentation follows progressive disclosure principles:
- **Layer 1**: Essential information to get started quickly
- **Layer 2**: Core features and common use cases
- **Layer 3**: Advanced configuration and production deployment

Each layer builds on the previous one, allowing users to deepen their understanding as needed without being overwhelmed by advanced details upfront.

## Contributing

When adding new features or capabilities:
1. Update the relevant OpenSpec spec with new requirements and scenarios
2. Add documentation to the appropriate layer in docs/
3. Update this README if adding new documentation files
4. Ensure progressive disclosure is maintained (simple → complex)

## Quick Reference

| Want to... | Go to... |
|------------|----------|
| Generate first video | [quick-start.md](quick-start.md) |
| Learn all generation modes | [generation-modes.md](generation-modes.md) |
| Optimize for production | [advanced-configuration.md](advanced-configuration.md) |
| Understand T2V requirements | [spec-text-to-video](../openspec/specs/spec-text-to-video.md) |
| Understand Avatar requirements | [spec-avatar-single](../openspec/specs/spec-avatar-single.md) |
| Set up multi-GPU | [advanced-configuration.md](advanced-configuration.md#multi-gpu-setup) |
| Troubleshoot issues | [quick-start.md](quick-start.md#troubleshooting) |
