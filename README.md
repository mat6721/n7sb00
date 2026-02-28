# OpenClaw 一键安装器

🦊 一行命令部署 OpenClaw AI 网关

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/mat/openclaw-installer/main/install.sh | bash

# Windows (管理员 PowerShell)
Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mat/openclaw-installer/main/install-windows.ps1' -UseBasicParsing).Content
```

---

## ✨ 特性

- ⚡ **一键安装** - 一行命令完成所有配置
- 🔧 **自动环境** - 自动安装 Node.js、pnpm、nvm
- 💻 **多平台** - 支持 macOS、Linux、Windows (WSL2)
- 🧪 **自动测试** - GitHub Actions CI 持续验证

---

## 🚀 快速开始

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/mat/openclaw-installer/main/install.sh | bash
```

### Windows

1. 以**管理员身份**打开 PowerShell
2. 运行：

```powershell
Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mat/openclaw-installer/main/install-windows.ps1' -UseBasicParsing).Content
```

3. 按提示重启电脑（首次安装 WSL2 需要）
4. 再次运行同一命令完成 OpenClaw 安装

---

## 📋 安装内容

| 组件 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 22.12.0 | JavaScript 运行时 |
| pnpm | 最新版 | 包管理器 |
| nvm | 最新版 | Node 版本管理器 |
| OpenClaw | 最新版 | AI 网关服务 |
| WSL2 + Ubuntu | 最新版 | Windows 子系统 (仅 Windows) |

---

## 💻 系统要求

- **macOS**: 10.14+ (Intel/Apple Silicon)
- **Linux**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- **Windows**: Windows 10 2004+ 或 Windows 11 (需 WSL2)

---

## 📁 仓库结构

```
.
├── install.sh              # macOS/Linux 安装脚本
├── install-windows.ps1     # Windows 安装脚本
├── LICENSE                 # MIT 许可证
├── README.md               # 本文件
└── .github/
    └── workflows/
        └── test.yml        # CI 测试配置
```

---

## 🔧 安装后使用

```bash
# 检查状态
openclaw status

# 启动网关
openclaw gateway start

# 查看帮助
openclaw --help
```

配置文件位于 `~/.openclaw/workspace/`：
- `IDENTITY.md` - AI 身份配置
- `USER.md` - 用户配置
- `SOUL.md` - 个性配置

---

## ❓ 常见问题

**Q: Windows 安装失败？**

A: 确保：
1. 以管理员身份运行 PowerShell
2. Windows 版本 >= 10 2004 (Build 19041)
3. BIOS 中启用了虚拟化

**Q: 如何卸载？**

```bash
# 卸载 OpenClaw
npm uninstall -g openclaw

# 删除配置
rm -rf ~/.openclaw
```

**Q: 如何更新？**

```bash
npm update -g openclaw
```

---

## 🤝 贡献

欢迎提交 Issue 和 PR！

---

## 📜 许可证

[MIT](LICENSE)

---

## 🔗 相关链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Discord](https://discord.com/invite/clawd)
