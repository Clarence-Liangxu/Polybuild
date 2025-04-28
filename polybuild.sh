#!/usr/bin/env bash
set -euo pipefail

LLVM_BASE_URL="https://github.com/llvm/llvm-project/archive/refs/tags"
INSTALL_PREFIX="/usr/local/llvm"

# 支持的 LLVM 版本列表
VERSIONS=("20.1.3" "19.1.7" "18.1.6" "17.0.6" "16.0.6" "15.0.7" "14.0.6")

echo "Select LLVM version to install:"
echo "(Type 'q' to quit.)"

select VERSION in "${VERSIONS[@]}"; do
    if [[ "$REPLY" == "q" || "$REPLY" == "Q" ]]; then
        echo "Quitting."
        exit 0
    elif [[ -n "${VERSION:-}" ]]; then
        echo "You selected LLVM version: $VERSION"
        break
    else
        echo "Invalid selection."
    fi
done

# ==== 下载 + 编译 + 安装 ====

WORK_DIR="/tmp/llvm_build_$VERSION"
rm -rf $WORK_DIR
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

LLVM_TAR="llvmorg-${VERSION}.tar.gz"
LLVM_URL="${LLVM_BASE_URL}/${LLVM_TAR}"

echo "Download URL: $LLVM_URL"

if [ ! -f "$LLVM_TAR" ]; then
    echo "Downloading LLVM $VERSION..."
    curl -LO "$LLVM_URL"
else
    echo "Source archive already exists: $LLVM_TAR"
fi

echo "Extracting..."
tar -xf "$LLVM_TAR"

cd "llvm-project-llvmorg-${VERSION}"

mkdir -p build
cd build

# 检测系统架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        LLVM_TARGET="X86"
        ;;
    arm64|aarch64)
        LLVM_TARGET="AArch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH"
echo "Setting LLVM_TARGETS_TO_BUILD to: $LLVM_TARGET"

echo "Configuring with CMake..."
cmake -G "Ninja" ../llvm \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}/${VERSION}" \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lldb" \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
  -DLLVM_TARGETS_TO_BUILD="$LLVM_TARGET"

echo "Building LLVM..."
ninja

echo "Installing to ${INSTALL_PREFIX}/${VERSION}..."
ninja install

echo "✅ LLVM $VERSION has been installed to ${INSTALL_PREFIX}/${VERSION}"
