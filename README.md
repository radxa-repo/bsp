# lbuild - Radxa Linux Kernel Build Tool

[![Build](https://github.com/radxa-repo/lbuild/actions/workflows/build.yml/badge.svg)](https://github.com/radxa-repo/lbuild/actions/workflows/build.yml)

`lbuild` aims to provide a standardized way to build Linux kernel for Radxa boards, so the resulting file can be easliy included in our image generation pipeline.

## Usage

### Local 

Please run the following command to check all available options:
```
git clone --depth 1 https://github.com/radxa-repo/lbuild.git
lbuild/lbuild
```

You can then build the bootloader with supported options. The resulting deb package will be stored in your current directory.

### Running in GitHub Action

Please check out our [GitHub workflows](https://github.com/radxa-repo/lbuild/tree/main/.github/workflows).
