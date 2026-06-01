kernel-4.19/build.sh:
- downloads required toolchain automatically
- sets up proper make build args

edit build.sh to run your desired make commands, and run it inside the kernel-4.19 folder


build-img.sh:
- requires magiskboot to be available
- builds a boot image based on the file "stock-boot.img" with the kernel replaced
- needs a full kernel build (i.e run it after building the kernel)