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

rtl8192de_block() {
  sed -n '/^define KernelPackage\/rtl8192de$/,/^endef$/p' "$realtek_file"
}

block=$(rtl8192de_block)
if [[ -z "$block" ]]; then
  echo "ERROR: upstream rtl8192de package definition is missing; patch needs review." >&2
  exit 1
elif grep -Eq 'DEPENDS.*\+kmod-rtl8192d-common' <<<"$block"; then
  echo "RTL8192DE common-module dependency is already present upstream."
else
  sed -i '/^define KernelPackage\/rtl8192de$/a\  DEPENDS+= +kmod-rtl8192d-common' "$realtek_file"
  block=$(rtl8192de_block)
  grep -Eq 'DEPENDS.*\+kmod-rtl8192d-common' <<<"$block"
  echo "Applied XGP RTL8192DE common-module dependency patch."
fi

rtw88_8723d_block() {
  sed -n '/^define KernelPackage\/rtw88-8723d$/,/^endef$/p' "$realtek_file"
}

block=$(rtw88_8723d_block)
if [[ -z "$block" ]]; then
  echo "ERROR: upstream rtw88-8723d package definition is missing; patch needs review." >&2
  exit 1
elif grep -Eq 'DEPENDS.*\+kmod-rtw88-8723x' <<<"$block"; then
  echo "RTW88 8723D common-module dependency is already present upstream."
else
  sed -i '/^define KernelPackage\/rtw88-8723d$/a\  DEPENDS+= +kmod-rtw88-8723x' "$realtek_file"
  block=$(rtw88_8723d_block)
  grep -Eq 'DEPENDS.*\+kmod-rtw88-8723x' <<<"$block"
  echo "Applied XGP RTW88 8723D common-module dependency patch."
fi

rtw89_8852be_block() {
  sed -n '/^define KernelPackage\/rtw89-8852be$/,/^endef$/p' "$realtek_file"
}

block=$(rtw89_8852be_block)
if [[ -z "$block" ]]; then
  echo "ERROR: upstream rtw89-8852be package definition is missing; patch needs review." >&2
  exit 1
elif grep -Eq 'DEPENDS.*\+kmod-rtw89-8852b-common' <<<"$block"; then
  echo "RTW89 8852BE common-module dependency is already present upstream."
else
  sed -i '/^define KernelPackage\/rtw89-8852be$/a\  DEPENDS+= +kmod-rtw89-8852b-common' "$realtek_file"
  block=$(rtw89_8852be_block)
  grep -Eq 'DEPENDS.*\+kmod-rtw89-8852b-common' <<<"$block"
  echo "Applied XGP RTW89 8852BE common-module dependency patch."
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
