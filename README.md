# Lenovo Tab K10 (TB-X6C6X) kernel
Kernel source code for Lenovo Tab K10 (TB-X6C6X variant)

This source tree contains additions and modifications, as I try to convert the device into a lightweight server

They are pretty minimal and shouldn't prevent a stock kernel from being built, but this scenario is outside the scope of this project (see below for more info)

# Building
A special building pipeline is used called AKB (see `akb_lib/README.MD` for more details)

AKB makes building pretty straightforward, as the toolchain will be automatically downloaded for you

You only need to make sure you have the appropriate dependencies for building a Linux kernel (and obviously, the android platform tools)

Run `akb_kernel.sh` and you will get all available options

## Typical build flow
```bash
./akb_kernel.sh tc # optional
./akb_kernel.sh config
./akb_kernel.sh build # this will use all available threads
```

## Building stock kernel

I **haven't tested** building a stock kernel, however you should be able to do something like this (configuring the build just with the device's stock config, `P98928AA1_defconfig`)

> [!NOTE]
> The built in config command uses the same defconfig with additional ones added on top

You will need to replace the kernel and dtb in a stock build image yourself, as currently there aren't any scripts just for that

- built kernel path: "kernel_build/arch/arm64/boot/Image"
- built dtb path: "kernel_build/arch/arm64/boot/dts/mediatek/mt6765.dtb"

```bash
./akb_kernel.sh tc # optional
./akb_kernel.sh run "P98928AA1_defconfig"
./akb_kernel.sh build
```