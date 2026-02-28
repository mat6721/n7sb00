# OpenClaw Windows 一键安装脚本
# 使用方法: 以管理员身份打开 PowerShell，然后运行:
# Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mat/openclaw-installer/main/install-windows.ps1' -UseBasicParsing).Content

param(
    [switch]$SkipWSLCheck,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# 颜色输出函数
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-ErrorLine { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# 检查管理员权限
function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-ErrorLine "请以管理员身份运行 PowerShell！"
    Write-Info "右键点击 PowerShell → 以管理员身份运行"
    exit 1
}

# 检查 Windows 版本
function Test-WindowsVersion {
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    $version = [System.Version]$osInfo.Version
    
    # Windows 10 2004 (build 19041) 或 Windows 11
    if ($version.Build -lt 19041) {
        Write-ErrorLine "需要 Windows 10 版本 2004 (Build 19041) 或更高版本"
        Write-Info "当前版本: $($osInfo.Caption) Build $($version.Build)"
        exit 1
    }
    
    Write-Success "Windows 版本检查通过: $($osInfo.Caption)"
}

# 检查虚拟化
function Test-Virtualization {
    try {
        $cpuInfo = Get-WmiObject -Class Win32_Processor
        if ($cpuInfo.VirtualizationFirmwareEnabled -eq $false) {
            Write-Warn "虚拟化可能未在 BIOS 中启用"
            Write-Info "请在 BIOS 中启用 Intel VT-x 或 AMD-V"
        } else {
            Write-Success "虚拟化已启用"
        }
    } catch {
        Write-Warn "无法检测虚拟化状态，请手动确认"
    }
}

# 安装 WSL2
function Install-WSL2 {
    Write-Info "正在安装 WSL2..."
    
    # 检查 WSL 是否已安装
    $wslCheck = wsl --list --quiet 2>&1
    if ($LASTEXITCODE -eq 0 -and -not $Force) {
        Write-Success "WSL 已安装"
        return
    }
    
    # 启用 WSL 功能
    Write-Info "启用 WSL 功能..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    
    # 设置 WSL 默认版本
    wsl --set-default-version 2 2>&1 | Out-Null
    
    # 安装 Ubuntu
    Write-Info "正在安装 Ubuntu..."
    wsl --install -d Ubuntu --no-launch
    
    Write-Success "WSL2 安装完成！需要重启电脑"
    Write-Info ""
    Write-Info "重启后请重新运行此脚本以继续安装 OpenClaw"
    Write-Info ""
    
    $restart = Read-Host "是否现在重启? (Y/n)"
    if ($restart -ne 'n') {
        Restart-Computer
    }
    exit 0
}

# 配置 Ubuntu
function Configure-Ubuntu {
    Write-Info "检查 Ubuntu 配置..."
    
    # 检查 Ubuntu 是否正在运行
    $ubuntuStatus = wsl --list --running | Select-String "Ubuntu"
    if (-not $ubuntuStatus) {
        Write-Info "启动 Ubuntu..."
        wsl -d Ubuntu -e true 2>&1 | Out-Null
        Start-Sleep -Seconds 3
    }
    
    Write-Success "Ubuntu 已就绪"
}

# 在 Ubuntu 中安装 OpenClaw
function Install-OpenClawInWSL {
    param([string]$InstallScriptUrl = "https://raw.githubusercontent.com/你的用户名/openclaw-installer/main/install.sh")
    
    Write-Info "在 Ubuntu 中安装 OpenClaw..."
    Write-Info "这可能需要几分钟，请耐心等待..."
    Write-Info ""
    
    # 创建安装命令
    $installCmd = @"
set -e
export DEBIAN_FRONTEND=noninteractive

# 更新系统
echo "[WSL] 更新系统包..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

# 安装基础依赖
echo "[WSL] 安装依赖..."
sudo apt-get install -y -qq curl git

# 下载并运行安装脚本
echo "[WSL] 下载 OpenClaw 安装脚本..."
curl -fsSL $InstallScriptUrl -o /tmp/install-openclaw.sh

echo "[WSL] 运行安装脚本..."
bash /tmp/install-openclaw.sh

# 验证安装
echo "[WSL] 验证安装..."
source ~/.bashrc 2>/dev/null || source ~/.profile 2>/dev/null
openclaw --version

# 创建快捷启动脚本
cat > ~/.openclaw-start.sh << 'EOF'
#!/bin/bash
source ~/.bashrc 2>/dev/null || source ~/.profile 2>/dev/null
echo "Starting OpenClaw Gateway..."
openclaw gateway start
EOF
chmod +x ~/.openclaw-start.sh

echo ""
echo "========================================"
echo "OpenClaw 安装完成！"
echo "========================================"
echo ""
echo "常用命令:"
echo "  openclaw --version     查看版本"
echo "  openclaw status        检查状态"
echo "  openclaw gateway start 启动网关"
echo "  ~/.openclaw-start.sh   快速启动脚本"
echo ""
"@
    
    # 在 WSL 中执行
    wsl -d Ubuntu -e bash -c $installCmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorLine "OpenClaw 安装失败"
        exit 1
    }
    
    Write-Success "OpenClaw 安装成功！"
}

# 创建 Windows 快捷方式
function Create-Shortcuts {
    Write-Info "创建快捷方式..."
    
    $wslScript = @'
@echo off
echo Starting OpenClaw in WSL2...
wsl -d Ubuntu -e bash -c "source ~/.bashrc 2>/dev/null; openclaw gateway start"
pause
'@
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $scriptPath = "$desktopPath\OpenClaw-Start.bat"
    
    $wslScript | Out-File -FilePath $scriptPath -Encoding ASCII
    
    Write-Success "快捷方式已创建: $scriptPath"
}

# 显示完成信息
function Show-Completion {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          ✅ OpenClaw Windows 安装完成！                ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Success "WSL2 + Ubuntu + OpenClaw 已全部安装完成！"
    Write-Host ""
    Write-Info "📁 配置文件位置:"
    Write-Host "   WSL 路径: \\wsl$\Ubuntu\home\$env:USERNAME\.openclaw\workspace"
    Write-Host ""
    Write-Info "🚀 快速开始:"
    Write-Host "   1. 打开 Ubuntu (开始菜单 → Ubuntu)"
    Write-Host "   2. 运行: openclaw gateway start"
    Write-Host "   3. 或双击桌面的 'OpenClaw-Start.bat'"
    Write-Host ""
    Write-Info "📚 常用命令:"
    Write-Host "   wsl                     进入 Ubuntu"
    Write-Host "   wsl -d Ubuntu           进入 Ubuntu (指定)"
    Write-Host "   wsl --shutdown          关闭 WSL"
    Write-Host ""
    Write-Info "🌐 更多信息: https://github.com/openclaw/openclaw"
    Write-Host ""
}

# 主函数
function Main {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     🦊 OpenClaw Windows 一键安装程序                   ║" -ForegroundColor Cyan
    Write-Host "║     WSL2 + Ubuntu + OpenClaw 自动部署                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 检查系统
    Test-WindowsVersion
    Test-Virtualization
    
    # 安装 WSL2
    Install-WSL2
    
    # 配置 Ubuntu
    Configure-Ubuntu
    
    # 安装 OpenClaw
    Install-OpenClawInWSL
    
    # 创建快捷方式
    Create-Shortcuts
    
    # 完成
    Show-Completion
}

# 运行主函数
Main
