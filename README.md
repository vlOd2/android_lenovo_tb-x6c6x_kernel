# Lenovo TB-X6C6X (Lenovo Tab K10)
Kernel source code for Lenovo TB-X6C6X, aka Lenovo Tab K10

This source tree contains additions and modifications, as I try to convert the device into a lightweight server

# Building
A special building pipeline is used called AKB (see `akb_lib/README.MD`)

Run `akb_kernel.sh` and you will get all available options

Typical flow goes like this:
```bash
./akb_kernel.sh tc # optional
./akb_kernel.sh config
./akb_kernel.sh build
```