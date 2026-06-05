How to automatically create a deployable boot image:
- Make sure to have magiskboot available in your PATH (grab it from an apk and rename the appropriate lib as magiskboot)
- Create a folder called base
- Copy your boot partition as boot.img inside that
- Compile the kernel
- Run deploy.sh

You can then flash out/new_boot.img