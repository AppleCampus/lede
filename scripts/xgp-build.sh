#!/usr/bin/env bash
# 在 LEDE 源码根目录执行：bash scripts/xgp-build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> feeds update/install"
./scripts/feeds update -a
./scripts/feeds install -a
./scripts/feeds install -a -f -p qmodem

echo "==> apply config"
cp xgp.config .config
make defconfig

echo "==> verify device selected"
grep -Fxq "CONFIG_TARGET_rockchip_armv8_DEVICE_nlnet_xiguapi-v3=y" .config

echo "==> qmodem default slots (XGP)"
mkdir -p files/etc/config
if [ -f feeds/qmodem/application/qmodem/files/etc/config/qmodem ]; then
  cat feeds/qmodem/application/qmodem/files/etc/config/qmodem > files/etc/config/qmodem
elif [ -f feeds/qmodem/luci/luci-app-qmodem/root/etc/config/qmodem ]; then
  cat feeds/qmodem/luci/luci-app-qmodem/root/etc/config/qmodem > files/etc/config/qmodem
fi

cat >> files/etc/config/qmodem <<'EOF'

config modem-slot 'wwan'
	option type 'usb'
	option slot '8-1'
	option net_led 'blue:net'
	option alias 'wwan'

config modem-slot 'mpcie1'
	option type 'pcie'
	option slot '0001:11:00.0'
	option net_led 'blue:net'
	option alias 'mpcie1'

config modem-slot 'mpcie2'
	option type 'pcie'
	option slot '0002:21:00.0'
	option net_led 'blue:net'
	option alias 'mpcie2'
EOF

year=$(date +%y)
month=$(date +%-m)
day=$(date +%-d)
hour=$(date +%-H)
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/zzzz-version <<EOF
echo "DISTRIB_REVISION='R${year}.${month}.${day}.${hour}'" >> /etc/openwrt_release
/bin/sync
EOF

echo "ZZ_BUILD_DATE='$(date "+%Y-%m-%d %H:%M:%S %z")'" > files/etc/zz_build_id
echo "ZZ_BUILD_HOST='$(hostname)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_LEDE_HASH='$(git rev-parse HEAD)'" >> files/etc/zz_build_id

echo "==> download"
make download -j8

echo "==> compile"
make V=s -j"$(nproc)"

echo "==> outputs"
ls -lah bin/targets/rockchip/armv8/ || true
