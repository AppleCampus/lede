#!/usr/bin/env bash
# 在 LEDE 源码根目录执行：bash scripts/xgp-prepare.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> feeds.conf"
cp feeds.conf.default feeds.conf
cat >> feeds.conf <<'EOF'

src-git qmodem https://github.com/FUjr/QModem.git;main
EOF

echo "==> clone extra packages"
mkdir -p package/zz

clone_or_pull() {
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only || git -C "$dir" pull
  else
    rm -rf "$dir"
    git clone --depth 1 "$url" "$dir"
  fi
}

clone_or_pull https://github.com/jerrykuku/luci-app-argon-config.git package/zz/luci-app-argon-config
clone_or_pull https://github.com/derisamedia/luci-theme-alpha.git package/zz/luci-theme-alpha
clone_or_pull https://github.com/zzzz0317/kmod-fb-tft-gc9307.git package/zz/kmod-fb-tft-gc9307
clone_or_pull https://github.com/zzzz0317/xgp-v3-screen.git package/zz/xgp-v3-screen

echo "==> overlay files"
# 保留仓库内 files/；若没有则从作者仓拉一份默认
if [ ! -d files/etc ]; then
  echo "files/ 不完整，从 zzzz0317/lede-xgp-auto-build 拉取 files/"
  rm -rf /tmp/xgp-files
  git clone --depth 1 https://github.com/zzzz0317/lede-xgp-auto-build.git /tmp/xgp-files
  rm -rf files
  cp -a /tmp/xgp-files/files .
fi

echo "==> config"
if [ ! -f xgp.config ]; then
  echo "缺少 xgp.config，从作者仓下载"
  curl -fsSL -o xgp.config \
    https://raw.githubusercontent.com/zzzz0317/lede-xgp-auto-build/main/xgp.config
fi

# 确保选中西瓜皮机型
if ! grep -q 'CONFIG_TARGET_rockchip_armv8_DEVICE_nlnet_xiguapi-v3=y' xgp.config; then
  echo "ERROR: xgp.config 未选中 nlnet_xiguapi-v3"
  exit 1
fi

# 6.12+ panfrost 需要 drm_shmem_helper
if grep -q 'CONFIG_PACKAGE_kmod-drm-panfrost=y' xgp.config; then
  if ! grep -q 'CONFIG_PACKAGE_kmod-drm-shmem-helper=y' xgp.config; then
    echo 'CONFIG_PACKAGE_kmod-drm-shmem-helper=y' >> xgp.config
  fi
fi

echo "prepare done"
