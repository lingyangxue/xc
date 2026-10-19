#!/bin/bash
# 在 macOS 或装有 Theos 的 Linux 上构建 ClownFeature.dylib
set -e

if [ -z "$THEOS" ]; then
  export THEOS="${THEOS:-$HOME/theos}"
fi

if [ ! -d "$THEOS" ]; then
  echo "未找到 Theos，正在安装..."
  git clone --recursive https://github.com/theos/theos.git "$THEOS"
  # iOS 交叉编译需要 Xcode（macOS）；Linux 下请自行配置 iOS SDK
fi

cd "$(dirname "$0")"
make clean
make package          # 生成 .deb（内含 ClownFeature.dylib）
# 只要 dylib 的话：make 后取 .theos/obj/debug/ClownFeature.dylib
echo "完成：查看 packages/ 目录下的 deb，或 .theos/obj/*/ClownFeature.dylib"
