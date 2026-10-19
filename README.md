# GitHub 编译补丁说明

## 1. Makefile 修改（必做）
文件：ClownFeature/ClownFeature/Makefile
将   ARCHS = arm64 arm64e
改为 ARCHS = arm64
（GitHub macos runner 的 Xcode 15+ 不再支持 arm64e）

## 2. 放置 workflow
把 .github/workflows/build.yml 放到仓库根目录。

## 3. 推送后
Actions 页面 → 最新运行 → Artifacts → 下载 ClownFeature-deb
