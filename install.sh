#!/bin/bash
#
# OpenClaw 一键安装脚本
# 支持: macOS, Linux
# 使用方法: curl -fsSL https://raw.githubusercontent.com/mat6721/openclaw-installer/main/install.sh | bash
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

if [[ "$OS" == "unknown" ]]; then
    log_error "不支持的操作系统: $OSTYPE"
    exit 1
fi

log_info "检测到操作系统: $OS"

# 检测架构
detect_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64) echo "x64" ;;
        amd64) echo "x64" ;;
        arm64) echo "arm64" ;;
        aarch64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

ARCH=$(detect_arch)
log_info "检测到架构: $ARCH"

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 获取最新 Node.js LTS 版本
get_latest_node_lts() {
    curl -fsSL https://nodejs.org/dist/index.json 2>/dev/null | grep -o '"version":"v[^"]*"' | grep -v 'rc\|nightly\|beta' | head -1 | sed 's/"version":"v//;s/"$//'
}

# 安装 Node.js
install_nodejs() {
    log_info "开始安装 Node.js..."
    
    if command_exists nvm; then
        log_info "检测到 nvm，使用 nvm 安装 Node.js..."
        local latest_lts
        latest_lts=$(get_latest_node_lts)
        log_info "安装 Node.js v${latest_lts}..."
        nvm install "v${latest_lts}"
        nvm use "v${latest_lts}"
        nvm alias default "v${latest_lts}"
    elif command_exists brew && [[ "$OS" == "macos" ]]; then
        log_info "使用 Homebrew 安装 Node.js..."
        brew install node@22
        brew link node@22 --force 2>/dev/null || true
    else
        log_info "安装 nvm 并使用 nvm 安装 Node.js..."
        
        # 安装 nvm
        export NVM_DIR="$HOME/.nvm"
        if [[ ! -d "$NVM_DIR" ]]; then
            log_info "安装 nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        fi
        
        # 加载 nvm
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # 安装 Node.js
        local latest_lts
        latest_lts=$(get_latest_node_lts)
        log_info "安装 Node.js v${latest_lts}..."
        nvm install "v${latest_lts}"
        nvm use "v${latest_lts}"
        nvm alias default "v${latest_lts}"
    fi
    
    # 验证安装
    if ! command_exists node; then
        log_error "Node.js 安装失败"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    log_success "Node.js 安装成功: $NODE_VERSION"
    
    # 检查版本
    local major_version
    major_version=$(echo "$NODE_VERSION" | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$major_version" -lt 22 ]]; then
        log_warn "Node.js 版本过低，需要 >= 22.12.0"
        log_info "尝试升级到最新版本..."
        if command_exists nvm; then
            local latest_lts
            latest_lts=$(get_latest_node_lts)
            nvm install "v${latest_lts}"
            nvm use "v${latest_lts}"
            nvm alias default "v${latest_lts}"
        fi
    fi
}

# 安装 pnpm
install_pnpm() {
    log_info "开始安装 pnpm..."
    
    if command_exists pnpm; then
        log_success "pnpm 已安装: $(pnpm --version)"
        return 0
    fi
    
    # 使用 npm 安装 pnpm
    npm install -g pnpm
    
    # 设置 pnpm 环境变量
    if [[ -n "$PNPM_HOME" ]]; then
        export PNPM_HOME="$PNPM_HOME"
    else
        export PNPM_HOME="$HOME/Library/pnpm"
        if [[ "$OS" == "linux" ]]; then
            export PNPM_HOME="$HOME/.local/share/pnpm"
        fi
    fi
    
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
    
    if ! command_exists pnpm; then
        log_error "pnpm 安装失败"
        exit 1
    fi
    
    log_success "pnpm 安装成功: $(pnpm --version)"
}

# 安装 OpenClaw
install_openclaw() {
    log_info "开始安装 OpenClaw..."
    
    # 检查是否已安装
    if command_exists openclaw; then
        log_warn "OpenClaw 已安装: $(openclaw --version 2>/dev/null || echo 'unknown')"
        log_info "如需重新安装，请先卸载: npm uninstall -g openclaw"
        return 0
    fi
    
    # 使用 npm 安装 openclaw
    log_info "正在下载并安装 OpenClaw (这可能需要几分钟)..."
    npm install -g openclaw
    
    # 验证安装
    if ! command_exists openclaw; then
        log_error "OpenClaw 安装失败"
        exit 1
    fi
    
    log_success "OpenClaw 安装成功!"
    log_info "版本: $(openclaw --version 2>/dev/null || echo 'unknown')"
}

# 初始化 OpenClaw 配置
init_openclaw() {
    log_info "初始化 OpenClaw..."
    
    # 创建工作目录
    local workspace_dir
    workspace_dir="$HOME/.openclaw/workspace"
    mkdir -p "$workspace_dir"
    mkdir -p "$workspace_dir/memory"
    
    log_success "工作目录已创建: $workspace_dir"
    
    # 检查是否需要配置
    if [[ -f "$workspace_dir/AGENTS.md" ]]; then
        log_info "OpenClaw 已配置，跳过初始化"
        return 0
    fi
    
    log_info "首次安装完成！"
    log_info ""
    log_info "接下来你可以:"
    log_info "  1. 运行 'openclaw status' 检查状态"
    log_info "  2. 运行 'openclaw gateway start' 启动网关"
    log_info "  3. 访问 ~/.openclaw/workspace 查看配置文件"
    log_info ""
    log_info "配置文件位置:"
    log_info "  - AGENTS.md    - 代理配置"
    log_info "  - IDENTITY.md  - 身份配置"
    log_info "  - USER.md      - 用户配置"
    log_info "  - SOUL.md      - 个性配置"
}

# 添加环境变量到 shell 配置
setup_shell_env() {
    local shell_rc=""
    
    if [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
        if [[ "$OS" == "macos" ]]; then
            shell_rc="$HOME/.bash_profile"
        fi
    else
        shell_rc="$HOME/.profile"
    fi
    
    log_info "配置 shell 环境: $shell_rc"
    
    # 添加 nvm 配置
    if ! grep -q "NVM_DIR" "$shell_rc" 2>/dev/null; then
        cat >> "$shell_rc" << 'EOF'

# OpenClaw - Node.js Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
        log_info "已添加 nvm 配置到 $shell_rc"
    fi
    
    # 添加 pnpm 配置
    if ! grep -q "PNPM_HOME" "$shell_rc" 2>/dev/null; then
        local pnpm_home
        pnpm_home="$HOME/Library/pnpm"
        if [[ "$OS" == "linux" ]]; then
            pnpm_home="$HOME/.local/share/pnpm"
        fi
        cat >> "$shell_rc" << EOF

# OpenClaw - pnpm
export PNPM_HOME="$pnpm_home"
case ":\$PATH:" in
  *":\$PNPM_HOME:"*) ;;
  *) export PATH="\$PNPM_HOME:\$PATH" ;;
esac
EOF
        log_info "已添加 pnpm 配置到 $shell_rc"
    fi
    
    log_info "请运行 'source $shell_rc' 或重启终端以应用环境变量"
}

# 主安装流程
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║          🦊 OpenClaw 一键安装脚本                      ║"
    echo "║     多通道 AI 网关 - 让 AI 无处不在                    ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "开始安装流程..."
    log_info "操作系统: $OS ($ARCH)"
    
    # 检查 Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version)
        log_info "Node.js 已安装: $NODE_VERSION"
        
        local major_version
        major_version=$(echo "$NODE_VERSION" | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$major_version" -lt 22 ]]; then
            log_warn "Node.js 版本过低 (需要 >= 22.12.0)"
            install_nodejs
        else
            log_success "Node.js 版本符合要求"
        fi
    else
        log_info "未检测到 Node.js，开始安装..."
        install_nodejs
    fi
    
    # 安装 pnpm
    install_pnpm
    
    # 安装 OpenClaw
    install_openclaw
    
    # 初始化配置
    init_openclaw
    
    # 配置 shell 环境
    setup_shell_env
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║          ✅ OpenClaw 安装完成!                         ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    log_success "OpenClaw 已成功安装到你的系统!"
    echo ""
    echo "📚 快速开始:"
    echo "   openclaw --help        查看帮助"
    echo "   openclaw status        检查状态"
    echo "   openclaw gateway start 启动网关服务"
    echo ""
    echo "📁 工作目录: ~/.openclaw/workspace"
    echo ""
    echo "⚠️  注意: 请运行 'source ~/.zshrc' (或 ~/.bashrc) 以应用环境变量"
    echo ""
    echo "🌐 更多信息: https://github.com/openclaw/openclaw"
    echo ""
}

# 运行主函数
main
