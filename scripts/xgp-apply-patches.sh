#!/usr/bin/env bash
set -euo pipefail

video_file=package/kernel/linux/modules/video.mk
realtek_file=package/kernel/mac80211/realtek.mk
mac80211_file=package/kernel/mac80211/Makefile

test -f "$video_file"
test -f "$realtek_file"
test -f "$mac80211_file"

panfrost_block() {
  sed -n '/^define KernelPackage\/drm-panfrost$/,/^endef$/p' "$video_file"
}

block=$(panfrost_block)
if grep -q 'kmod-drm-shmem-helper' <<<"$block"; then
  echo "Panfrost dependency is already present upstream."
elif ! grep -q '^[[:space:]]*DEPENDS:.*+kmod-drm-sched' <<<"$block"; then
  echo "ERROR: upstream panfrost package definition changed; patch needs review." >&2
  exit 1
else
  sed -i '/^define KernelPackage\/drm-panfrost$/,/^endef$/ s#^\([[:space:]]*DEPENDS:=.*+kmod-drm-sched\)$#\1 +kmod-drm-shmem-helper#' "$video_file"
  block=$(panfrost_block)
  grep -q 'kmod-drm-shmem-helper' <<<"$block"
  echo "Applied XGP panfrost dependency patch."
fi

if ! grep -q '^define KernelPackage/rtl8192d-common$' "$realtek_file"; then
  cat >>"$realtek_file" <<'EOF'

# XGP compatibility package definitions. Keep the rest of realtek.mk on upstream.
PKG_DRIVERS += rtl8192d-common rtw88-8723x rtw89-8852b-common
config-$(call config_package,rtl8192d-common) += RTL8192D_COMMON

define KernelPackage/rtl8192d-common
  $(call KernelPackage/mac80211/Default)
  TITLE:=Realtek RTL8192DE common support module
  DEPENDS+= +kmod-rtlwifi
  FILES:= $(PKG_BUILD_DIR)/drivers/net/wireless/realtek/rtlwifi/rtl8192d/rtl8192d-common.ko
  HIDDEN:=1
endef

define KernelPackage/rtw88-8723x
  $(call KernelPackage/mac80211/Default)
  TITLE:=Realtek RTL8723D common support
  DEPENDS+= +kmod-rtw88
  FILES:= $(PKG_BUILD_DIR)/drivers/net/wireless/realtek/rtw88/rtw88_8723x.ko
  HIDDEN:=1
endef

define KernelPackage/rtw89-8852b-common
  $(call KernelPackage/mac80211/Default)
  TITLE:=Realtek RTL8852B common support
  DEPENDS+= +kmod-rtw89
  FILES:= $(PKG_BUILD_DIR)/drivers/net/wireless/realtek/rtw89/rtw89_8852b_common.ko
  HIDDEN:=1
endef
EOF
  echo "Applied XGP legacy Realtek package overlay."
else
  echo "Legacy Realtek package overlay is already present upstream."
fi

grep -q '^define KernelPackage/rtl8192d-common$' "$realtek_file"
grep -q '^define KernelPackage/rtw88-8723x$' "$realtek_file"
grep -q '^define KernelPackage/rtw89-8852b-common$' "$realtek_file"
grep -Fq 'KLIB_BUILD="$(LINUX_DIR)"' "$mac80211_file"
grep -Fq '$(eval $(foreach drv,$(PKG_DRIVERS),$(call KernelPackage,$(drv))))' "$mac80211_file"
