#!/usr/bin/env bash
set -euo pipefail

# 默认编译联发科无线网卡，可以通过环境变量覆盖
MODULE_PATH=${MODULE_PATH:-"drivers/net/wireless/mediatek"}

echo "=== 正在准备独立模块编译环境 ==="
mkdir -p kernel_workspace
cd kernel_workspace

# 1. 拉取 AOSP 源码 (深度为1，加快速度)
echo ">>> 正在拉取内核源码..."
repo init -u https://android.googlesource.com/kernel/manifest -b common-android12-5.10-lts --depth=1
repo sync -c --no-tags --no-clone-bundle --current-branch -j$(nproc)

cd common

# 2. 拉取主仓库的 Module.symvers (等咱们主仓库出包并上传后，这里就能直接拉)
echo ">>> 正在下载主内核的 Module.symvers..."
# 注意：这里的链接是占位的，等主内核 YAML 改了并上传后，就能秒拉
wget -q https://github.com/isaquxet08-ai/Kernel-Builder-GKI-Susfs/releases/latest/download/Module.symvers -O Module.symvers || echo "⚠️ 没找到 Module.symvers，如果报错请检查主仓库是否已上传！"

# 3. 编译指定模块
echo ">>> 开始单独编译模块: ${MODULE_PATH}"
# M= 指定编译路径
make ARCH=arm64 CC=clang LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- \
  M=${MODULE_PATH} modules

# 4. 收集所有 .ko 文件并打包
echo ">>> 收集 .ko 模块文件..."
mkdir -p ../output
find ${MODULE_PATH} -name "*.ko" -exec cp {} ../output/ \;
cd ../output

# 打包
cd ..
if [ -n "$(ls -A output)" ]; then
    zip -r9 ../modules_${MODULE_PATH//\//_}.zip output/
    echo ">>> 编译并打包成功！"
else
    echo "❌ 未找到任何 .ko 文件！"
    exit 1
fi
