#!/usr/bin/env bash
set -euo pipefail

# 你要编译的模块路径，比如 drivers/net/wireless/mediatek
MODULE_PATH=${MODULE_PATH:-"drivers/net/wireless/mediatek"}

echo "=== 正在准备模块编译环境 ==="
mkdir -p kernel_workspace
cd kernel_workspace

# 1. 拉取 AOSP 源码 (为了节省时间，可以像主仓库一样用 repo sync)
# 注意：这里的 branch 必须和主内核编译时的分支绝对一致！
repo init -u https://android.googlesource.com/kernel/manifest -b common-android12-5.10-lts --depth=1
repo sync -c --no-tags --no-clone-bundle --current-branch -j$(nproc)

cd common

# 2. 拉取主仓库编译出的 Module.symvers (需要你提前传到某个地方，比如 Release)
echo ">>> 正在下载主内核的 Module.symvers..."
# 这里先占位，等咱们主仓库出包了，把真实链接填上
# wget -q https://github.com/isaquxet08-ai/Kernel-Builder-GKI-Susfs/releases/latest/download/Module.symvers -O Module.symvers

# 3. 编译指定模块
echo ">>> 开始单独编译模块: ${MODULE_PATH}"
make ARCH=arm64 CC=clang LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- \
  M=${MODULE_PATH} modules || true

# 4. 收集所有 .ko 文件并打包
echo ">>> 收集 .ko 模块文件..."
find ${MODULE_PATH} -name "*.ko" -exec cp {} ../ \;

cd ..
zip -r9 ../modules_${MODULE_PATH//\//_}.zip *.ko
