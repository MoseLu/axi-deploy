#!/bin/bash

# 服务器设置脚本
# 用于配置服务器以支持SSH部署

set -e

# 默认参数
DEPLOY_USER="deploy"
DEPLOY_GROUP="deploy"
APP_DIR="/var/www/app"
SSH_PORT="22"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -u, --user USER         部署用户名 (默认: deploy)"
    echo "  -g, --group GROUP       部署用户组 (默认: deploy)"
    echo "  -d, --dir DIR           应用目录 (默认: /var/www/app)"
    echo "  -p, --port PORT         SSH端口 (默认: 22)"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -u mydeploy -d /opt/myapp"
    echo "  $0 --user deploy --dir /var/www/myapp"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            DEPLOY_USER="$2"
            shift 2
            ;;
        -g|--group)
            DEPLOY_GROUP="$2"
            shift 2
            ;;
        -d|--dir)
            APP_DIR="$2"
            shift 2
            ;;
        -p|--port)
            SSH_PORT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo "错误: 此脚本需要root权限运行"
   echo "请使用: sudo $0"
   exit 1
fi

echo "🚀 开始配置服务器..."
echo "部署用户: $DEPLOY_USER"
echo "部署用户组: $DEPLOY_GROUP"
echo "应用目录: $APP_DIR"
echo "SSH端口: $SSH_PORT"
echo ""

# 创建部署用户组
echo "📦 创建用户组..."
if ! getent group "$DEPLOY_GROUP" > /dev/null 2>&1; then
    groupadd "$DEPLOY_GROUP"
    echo "✅ 创建用户组: $DEPLOY_GROUP"
else
    echo "ℹ️  用户组已存在: $DEPLOY_GROUP"
fi

# 创建部署用户
echo "👤 创建部署用户..."
if ! id "$DEPLOY_USER" > /dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$DEPLOY_GROUP" "$DEPLOY_USER"
    echo "✅ 创建用户: $DEPLOY_USER"
else
    echo "ℹ️  用户已存在: $DEPLOY_USER"
fi

# 创建应用目录
echo "📁 创建应用目录..."
mkdir -p "$APP_DIR"
chown "$DEPLOY_USER:$DEPLOY_GROUP" "$APP_DIR"
chmod 755 "$APP_DIR"
echo "✅ 创建应用目录: $APP_DIR"

# 创建SSH目录
echo "🔐 配置SSH..."
mkdir -p /home/"$DEPLOY_USER"/.ssh
chown "$DEPLOY_USER:$DEPLOY_GROUP" /home/"$DEPLOY_USER"/.ssh
chmod 700 /home/"$DEPLOY_USER"/.ssh

# 创建authorized_keys文件
touch /home/"$DEPLOY_USER"/.ssh/authorized_keys
chown "$DEPLOY_USER:$DEPLOY_GROUP" /home/"$DEPLOY_USER"/.ssh/authorized_keys
chmod 600 /home/"$DEPLOY_USER"/.ssh/authorized_keys
echo "✅ 配置SSH目录"

# 配置sudo权限
echo "🔧 配置sudo权限..."
SUDOERS_FILE="/etc/sudoers.d/$DEPLOY_USER"
cat > "$SUDOERS_FILE" << EOF
# $DEPLOY_USER sudo权限配置
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl status nginx
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/pm2 *
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/docker *
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/docker-compose *
EOF
chmod 440 "$SUDOERS_FILE"
echo "✅ 配置sudo权限"

# 安装常用工具
echo "📦 安装常用工具..."
if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    apt-get update
    apt-get install -y rsync curl wget git unzip
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum update -y
    yum install -y rsync curl wget git unzip
elif command -v dnf &> /dev/null; then
    # Fedora
    dnf update -y
    dnf install -y rsync curl wget git unzip
else
    echo "⚠️  无法识别包管理器，请手动安装rsync、curl、wget、git、unzip"
fi

# 安装Node.js (可选)
echo "📦 安装Node.js..."
if command -v node &> /dev/null; then
    echo "ℹ️  Node.js已安装"
else
    echo "安装Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
    echo "✅ Node.js安装完成"
fi

# 安装PM2 (可选)
echo "📦 安装PM2..."
if command -v pm2 &> /dev/null; then
    echo "ℹ️  PM2已安装"
else
    echo "安装PM2..."
    npm install -g pm2
    echo "✅ PM2安装完成"
fi

# 配置防火墙 (如果启用)
echo "🔥 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow "$SSH_PORT"
    echo "✅ UFW防火墙配置完成"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port="$SSH_PORT"/tcp
    firewall-cmd --reload
    echo "✅ firewalld配置完成"
fi

echo ""
echo "🎉 服务器配置完成!"
echo ""
echo "📋 配置摘要:"
echo "- 部署用户: $DEPLOY_USER"
echo "- 部署用户组: $DEPLOY_GROUP"
echo "- 应用目录: $APP_DIR"
echo "- SSH端口: $SSH_PORT"
echo ""
echo "🔧 下一步操作:"
echo "1. 将SSH公钥添加到 /home/$DEPLOY_USER/.ssh/authorized_keys"
echo "2. 测试SSH连接: ssh $DEPLOY_USER@$(hostname -I | awk '{print $1}')"
echo "3. 在GitHub仓库中配置Secrets"
echo ""
echo "💡 安全提示:"
echo "- 定期更新系统和软件包"
echo "- 监控SSH访问日志"
echo "- 考虑使用SSH密钥轮换" 