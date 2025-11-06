#!/bin/bash
set -e
ARCH="${1:-$ARCH}"
API_LEVEL="${2:-${API_LEVEL:-29}}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
OUT_DIR="${ROOT_DIR}/output"
mkdir -p "${OUT_DIR}"
VALID_ARCHES="aarch64 armv7 x86 x86_64 riscv64"
[[ -z "$ARCH" || ! " $VALID_ARCHES " =~ " $ARCH " ]] && {
    echo "Usage: $0 <aarch64|armv7|x86|x86_64|riscv64> [API_LEVEL]"
    echo "Default API_LEVEL: 29"
    exit 1
}
[[ -z "$ANDROID_NDK_ROOT" ]] && {
    echo "ERROR: ANDROID_NDK_ROOT not set"
    exit 1
}
[[ ! -d "$ANDROID_NDK_ROOT" ]] && {
    echo "ERROR: Invalid ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
    exit 1
}

[[ "$ARCH" == "riscv64" && "$API_LEVEL" -lt 35 ]] && API_LEVEL=


case "$ARCH" in
    aarch64) suffix=arm64-v8a ;;
    armv7)
        suffix=armeabi-v7a
        triple=armv7a-linux-androideabi
        rust=armv7-linux-androideabi
        ;;
    x86)
        suffix=86 
        triple=i686-linux-android
        rust=i686-linux-android
     ;;
    x86_64) suffix=x86_64 ;;
    riscv64) suffix=riscv64 ;;
    *)
        echo "Unsupported arch: $ARCH"
        exit 1
        ;;
esac

HOST="${triple:-$ARCH-linux-android}"
CLANG_TRIPLE="${triple:-$ARCH-linux-android}"
RUST_TARGET="${rust:-$ARCH-linux-android}"
ANDROID_ABI="$suffix"

TOOLCHAIN_ROOT="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"
BIN="$TOOLCHAIN_ROOT/bin"

for t in ar ranlib strip nm strings objdump objcopy; do
    export "${t^^}"="$BIN/llvm-$t"
done

export CC="$BIN/${CLANG_TRIPLE}${API_LEVEL}-clang"
export CXX="$BIN/${CLANG_TRIPLE}${API_LEVEL}-clang++"

case "$ARCH" in
    x86 | x86_64)
        export AS=$(command -v nasm > /dev/null 2>&1 && echo nasm || echo "$CC")
        ;;
    *) export AS="$CC" ;;
esac

export BUILD_DIR="$ROOT_DIR/build/android/$ARCH"
export PREFIX="$BUILD_DIR/prefix"

mkdir -p "$PREFIX"/{lib,lib64}/pkgconfig

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_ALLOW_CROSS=1
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
CFLAGS="-Os -ffunction-sections -fdata-sections -fvisibility=hidden -fomit-frame-pointer -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector -fmerge-all-constants -fno-exceptions -fno-rtti"
LDFLAGS="-Wl,--gc-sections -Wl,--strip-all -flto -fPIC"

export CFLAGS="${CFLAGS} -I$PREFIX/include $COMMON_FLAGS"
export CXXFLAGS="${CFLAGS} -I$PREFIX/include $COMMON_FLAGS"
export CPPFLAGS="-I$PREFIX/include -DNDEBUG -fPIC"
export LDFLAGS="${LDFLAGS} -L$PREFIX/lib -L$PREFIX/lib64"
export SYSROOT="$TOOLCHAIN_ROOT/sysroot"

build_x264() {
    echo "[+] Building x264 for $ARCH..."
    cd "$BUILD_DIR" || exit 1
    rm -rf x264
    git clone --depth 1 "https://code.videolan.org/videolan/x264.git"
    cd "x264"
    (make clean && make distclean) || true

    local cfg_host="$HOST"
    local asm_flags=""

    if [ "$ARCH" = "riscv64" ]; then
        cfg_host="riscv64-unknown-linux-gnu"
        sed -i 's/unknown/ok/' configure
        asm_flags="--disable-asm"
    elif [ "$ARCH" = "x86" ]; then
        asm_flags="--disable-asm"
    fi

    ./configure \
        --prefix="$PREFIX" \
        --host="$cfg_host" \
        --enable-static \
        --disable-cli \
        --disable-opencl \
        --enable-pic \
        $asm_flags \
        --extra-cflags="$CFLAGS -I$PREFIX/include" \
        --extra-ldflags="$LDFLAGS -L$PREFIX/lib"

    make -j"$(nproc)"
    make install

    echo "✔ x264 built successfully"
}

build_ffmpeg() {
    echo "Building FFmpeg for $ARCH..."
    cd "$BUILD_DIR" || exit 1
    rm -rf FFmpeg
    git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git
    cd FFmpeg

    NEON=()
    [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7" ]] && NEON=(--enable-neon)

    CONFIGURE_FLAGS=(
        --enable-cross-compile
        --prefix="$PREFIX"
        --host-cc="$(which gcc)"
        --cc="$CC"
        --cxx="$CXX"
        --ar="$AR"
        --nm="$NM"
        --ranlib="$RANLIB"
        --strip="$STRIP"
        --arch="$ARCH"
        --target-os=android
        --pkg-config-flags=--static
        --extra-cflags="${CFLAGS}"
        --extra-ldflags="${LDFLAGS} -static"
        --extra-libs="-lm"
        --enable-small
        --disable-debug
        --disable-shared
        --enable-pic
        --disable-doc
        --enable-gpl
        --enable-libx264
        "${NEON[@]}"
    )

    ./configure "${CONFIGURE_FLAGS[@]}"
    make -j"$(nproc)"
    make install

    cp "$PREFIX/bin/ffmpeg" "${OUT_DIR}/ffmpeg-${suffix}"
    cp "$PREFIX/bin/ffprobe" "${OUT_DIR}/ffprobe-${suffix}"

    echo "[+] FFmpeg built successfully "
}

build_btools() {
    cd "$BUILD_DIR"
    rm -rf btools
    git clone --depth 1 https://github.com/rhythmcache/Video-to-BootAnimation-Creator-Script.git btools
    cd btools
    mkdir -p .cargo
    cat > .cargo/config.toml << EOF
[target.$RUST_TARGET]
linker = "$CC"
rustflags = ["-C", "target-feature=+crt-static", "-C", "relocation-model=pic", "-C", "link-arg=-pie"]
EOF
    cargo build --release --target ${RUST_TARGET}
    cp target/${RUST_TARGET}/release/vid2boot "${OUT_DIR}/vid2boot-${suffix}"
    cp target/${RUST_TARGET}/release/boot2vid "${OUT_DIR}/boot2vid-${suffix}"
}

build_x264
build_ffmpeg
build_btools
rm -rf "$ROOT_DIR/build"
