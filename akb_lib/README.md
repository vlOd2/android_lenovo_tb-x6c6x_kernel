# AKB
AKB (Anyone Kan Build, originally Android Kernel Builder) is a simple bash build wrapper

As the original name suggests, this was initially made just to easily build the Android kernel, but has been expanded to be a generic wrapper

# Concepts
## Root builder
main AKB build script

- examples: akb_kernel.sh


## AKB environment
loaded by the root builder, it must at least declare the root directory

- examples: akb_kernel_env.sh


## Builder (or pure builder)
sub builder that can only be invoked by the root

> [!NOTE]
> Builders typically also depend on root builder specific functions and variables, not just common AKB ones, and thus are not "pure"

a builder that only uses common AKB functions and variables is known as a pure builder

## Common toolchain
common interface for using toolchains

- required function: tc::check and tc::use
- examples: akb_kernel_env.sh

> [!IMPORTANT]
> The common toolchain is not implemented by all root builders


## makebuild
make support for AKB

- required variables: AKB_MKB_SOURCE_DIR, AKB_MKB_BUILD_DIR, AKB_MKB_BUILD_ARGS
- requires common toolchain