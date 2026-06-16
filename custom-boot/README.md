# Custom boot image
This section is meant to build a **boot image** with the built kernel and a **custom ramdisk**

> [!IMPORTANT]
> The resulting image is not meant to and **cannot boot Android**, as I made it to use the tablet as a server

It's also probably not going to be appropriate for whatever use case you might have, as the init script has some hardcoded assumptions

# Structure

- **base/**
    - **base_bootfs/**: contains the base bootfs that will be built upon to make the final one
    - **base_img/**: contains the base image files that will be used to create a compatible image, you usually only need to modify the cmdline in header

- **tools/**: contains apps and tools that will be added on top of the base_bootfs

- **out/** (created by AKB)
    - **bootfs/**: the final bootfs used by the image, also where anything built from "tools/" outputs
    - **img/**: the build directory of the image, do not edit anything in there, as its automatically remade on each build
    - **new_boot.img**: the final, ready to flash, built image

# How to build
AKB makes this pretty straightforward, as the toolchain and tools source code will be automatically downloaded for you

You only need to make sure you have **magiskboot** in your path and the appropriate dependencies (mostly the same as the kernel)

You can get **magiskboot** by extracing the arch specific lib from the magisk apk and renaming it appropriately

Run `akb_cb.sh` and you will get all available options (`cb` stands for custom boot btw)

## Typical build flow
```bash
./akb_cb.sh init_fs
./akb_cb.sh tc # optional
./akb_cb.sh copy_all
./akb_cb.sh all_tools
./akb_cb.sh build_img # or build_and_flash_img
```