# 在你 fork 的 coolsnowwolf/lede 上用 Actions 编西瓜皮 V3

作者 `lede-xgp-auto-build` 不更新没关系：**板级已在 LEDE 主线**，
你 fork 的 LEDE 每次 Actions 都会用**当前最新源码**，这正是你要的。

## 1. 把这些文件丢进你的 LEDE fork 根目录

```
你的-lede-fork/
├── .github/workflows/xgp-build.yml
├── scripts/xgp-prepare.sh
├── scripts/xgp-build.sh
├── xgp.config                 # 首次可让脚本自动下载
└── files/                     # 可选；没有则 prepare 时自动从作者仓拉
```

本目录已生成前三个文件。`xgp.config` 很大，建议直接下载：

```bash
curl -L -o xgp.config \
  https://raw.githubusercontent.com/zzzz0317/lede-xgp-auto-build/main/xgp.config
```

`files/` 可选：

```bash
git clone --depth 1 https://github.com/zzzz0317/lede-xgp-auto-build.git /tmp/xgp
cp -a /tmp/xgp/files .
```

## 2. 推送到 GitHub

```bash
# 在你 clone 的 fork 里
cp -r /path/to/lede_xgp_workflow/.github .
cp -r /path/to/lede_xgp_workflow/scripts .
curl -L -o xgp.config \
  https://raw.githubusercontent.com/zzzz0317/lede-xgp-auto-build/main/xgp.config
chmod +x scripts/xgp-prepare.sh scripts/xgp-build.sh

git add .github scripts xgp.config
git commit -m "ci: add XGPv3 GitHub Actions build"
git push
```

## 3. 跑 Actions

1. 打开你的 fork → **Actions**
2. 启用 workflows（若提示）
3. 选 **XGPv3 Build** → **Run workflow**
4. 等 2–6 小时
5. 成功后：
   - **Artifacts** → `xgpv3-firmware`
   - 或 **Releases** 里下载 `*xiguapi-v3*sysupgrade.img.gz`

## 4. 刷机

- Web 升级（已有同类固件）或 RKDevTool
- PCIe 5G：**刷完拔 DC 断电一次**

## 5. 刷完验证 mt76 / HE160

```sh
opkg list-installed | grep mt792
iw phy | grep -i 160
# 再设 HE160 测 AP
```

## 常见失败

| 现象 | 处理 |
|------|------|
| 磁盘满 | workflow 已 maximize-build-space；仍满就减包 |
| feeds 挂 | 重跑；或改 `xgp-prepare.sh` 里 qmodem 分支 |
| 未选中 xiguapi-v3 | 检查 `xgp.config` 是否含 `DEVICE_nlnet_xiguapi-v3=y` |
| Release 权限 | 仓库 Settings → Actions → General → Workflow permissions 勾选 Read and write |
| 私有仓额度 | 改 Public 或自备 runner |

## 和作者 auto-build 的关系

| | 作者 auto-build | 你现在这套 |
|--|-----------------|------------|
| LEDE 版本 | 跑的时候 pull 最新 | **就是你 fork 的最新 master** |
| 屏幕/QModem | prepare 里 clone | 同样 clone |
| 默认配置 | xgp.config | 同一份 xgp.config |
| 维护 | 作者停了 | **你自己控** |
