# AKB
AKB (Anyone Kan Build, originally Android Kernel Builder) is a simple bash build wrapper

As the original name suggests, this was initially made just to easily build the Android kernel, but has been expanded to be a generic wrapper

# Concepts
## Root builder
main AKB build script

- examples: akb_kernel.sh


## AKB environment
defined by the root builder, it must at least declare the root directory (AKB_ROOT_DIR, must be absolute path)

its usually loaded from an external script by bigger builders

- examples: akb_kernel_env.sh


## Builder (or pure builder)
sub builder that can only be invoked by the root

> [!NOTE]
> Builders typically also depend on root builder specific functions and variables, not just common AKB ones, and thus are not "pure"

a builder that only uses common AKB functions and variables is known as a pure builder

## Common toolchain
common interface for using toolchains

- required functions:
    - `tc::check`: used to check the toolchain's state (must either exit or return non zero if failed)
    - `tc::use`: prepares the toolchain to be used (usually by adding to path, can also enable bash functions, etc...)

- example implementation: akb_kernel_tc.sh

> [!IMPORTANT]
> The common toolchain is not implemented by all root builders


## makebuild
make support for AKB

- requires variables:
    - `AKB_MKB_SOURCE_DIR` (**absolute path**): the directory to invoke make in
    
    - `AKB_MKB_BUILD_DIR` (**absolute path**): the directory expected (not passed to make by default) to be used as the output (used by the clean function)
    
    - `AKB_MKB_BUILD_ARGS` (**array**): arguments passed to make before the run function arguments (currently it's required that it contains a non empty item, use a bogus option flag if none)

- requires common toolchain

- exports functions:
    - `mkb::clean`: prompts the user to delete the folder defined by `AKB_MKB_BUILD_DIR`, optionally runs the function `mkb::extra_clean` if it exists (before deleting, but after prompting)
    
    - `mkb::run`: runs a make command, passing all arguments after `AKB_MKB_BUILD_ARGS`