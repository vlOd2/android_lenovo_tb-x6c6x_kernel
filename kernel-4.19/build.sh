#!/bin/bash
set -e
TC_DIR="toolchain"

GCC_TC_BRANCH="pie-gsi"
GCC_TC_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
GCC_TC_DIR="gcc-${GCC_TC_BRANCH}"

CLANG_TC_BRANCH="android11-gsi"
CLANG_TC_REV="clang-r383902"
CLANG_TC_URL="https://android.googlesource.com/platform//prebuilts/clang/host/linux-x86"
CLANG_CLONE_DIR="clang-${CLANG_TC_BRANCH}"
CLANG_TC_DIR="${CLANG_TC_REV}"

if [ ! -e "${TC_DIR}" ]; then
	echo "Downloading toolchain"
	
	if ! command -v "git" &>/dev/null; then
		echo "Could not find git"
		exit 1
	fi
	mkdir -p "${TC_DIR}"

	pushd "${TC_DIR}" &>/dev/null
		git clone --depth 1 -b "${GCC_TC_BRANCH}" "${GCC_TC_URL}" "${GCC_TC_DIR}"
		
		# Clone clang
		git clone --no-checkout --sparse --filter=tree:0 --depth=1 --single-branch -b "${CLANG_TC_BRANCH}" "${CLANG_TC_URL}" "${CLANG_CLONE_DIR}"
		git -C "${CLANG_CLONE_DIR}" sparse-checkout set --no-cone "/${CLANG_TC_REV}"
		git -C "${CLANG_CLONE_DIR}" checkout --progress --force

		mv "${CLANG_CLONE_DIR}/${CLANG_TC_REV}" "${CLANG_TC_DIR}"
		rm -rf "${CLANG_CLONE_DIR}"
	popd &>/dev/null
fi

export PATH="$PWD/${TC_DIR}/${CLANG_TC_DIR}/bin:${PATH}"
export PATH="$PWD/${TC_DIR}/${GCC_TC_DIR}/bin:${PATH}"

BUILD_ARGS=(
	"O=out"
	"ARCH=arm64"
	"CROSS_COMPILE=aarch64-linux-android-"
	
	"CC=clang"
	"NM=llvm-nm"
	"OBJCOPY=llvm-objcopy"
	"CLANG_TRIPLE=aarch64-linux-gnu-"
	
	"LD=ld.lld"
	"LD_LIBRARY_PATH=$PWD/${TC_DIR}/${CLANG_TC_DIR}/lib64:"
)

echo "Path: ${PATH}"
echo "Build args: ${BUILD_ARGS[@]}"

#echo "Cleaning kernel"
#make "${BUILD_ARGS[@]}" clean

echo "Configuring kernel"
make "${BUILD_ARGS[@]}" P98928AA1_defconfig docker-extra.config

echo "Building kernel"
make "${BUILD_ARGS[@]}" -j12

echo "Copying modules"
mkdir -p out/modules
make "${BUILD_ARGS[@]}" INSTALL_MOD_PATH=modules modules_install 
