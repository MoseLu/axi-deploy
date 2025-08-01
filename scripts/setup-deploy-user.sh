#!/bin/bash

# 设置deploy用户和SSH密钥的脚本

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
    echo "  -k, --generate-key      生成SSH密钥对"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -u deploy -d /var/www/myapp"
    echo "  $0 --generate-key"
}

# 解析命令行参数
GENERATE_KEY=false
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
        -k|--generate-key)
            GENERATE_KEY=true
            shift
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

echo "🚀 开始配置deploy用户..."
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

# 生成SSH密钥对
if [ "$GENERATE_KEY" = true ]; then
    echo "🔑 生成SSH密钥对..."
    
    # 切换到deploy用户生成密钥
    su - "$DEPLOY_USER" << 'EOF'
        ssh-keygen -t rsa -b 4096 -C "deploy@axi-deploy" -f ~/.ssh/id_rsa -N ""
        chmod 600 ~/.ssh/id_rsa
        chmod 644 ~/.ssh/id_rsa.pub
EOF
    
    echo "✅ SSH密钥生成完成"
    echo ""
    echo "📋 私钥内容 (用于GitHub Secrets):"
    echo "----------------------------------------"
    cat /home/"$DEPLOY_USER"/.ssh/id_rsa
    echo "----------------------------------------"
    echo ""
    echo "📋 公钥内容 (已添加到authorized_keys):"
    echo "----------------------------------------"
    cat /home/"$DEPLOY_USER"/.ssh/id_rsa.pub
    echo "----------------------------------------"
    
    # 将公钥添加到authorized_keys
    cat /home/"$DEPLOY_USER"/.ssh/id_rsa.pub >> /home/"$DEPLOY_USER"/.ssh/authorized_keys
    echo "✅ 公钥已添加到authorized_keys"
fi

echo ""
echo "🎉 deploy用户配置完成!"
echo ""
echo "📋 配置摘要:"
echo "- 部署用户: $DEPLOY_USER"
echo "- 部署用户组: $DEPLOY_GROUP"
echo "- 应用目录: $APP_DIR"
echo "- SSH端口: $SSH_PORT"
echo ""
echo "🔧 下一步操作:"
if [ "$GENERATE_KEY" = true ]; then
    echo "1. 将私钥内容添加到GitHub仓库的Secrets中"
    echo "2. 配置SERVER_HOST, SERVER_USER, SERVER_PORT, SERVER_KEY"
else
    echo "1. 运行 $0 --generate-key 生成SSH密钥"
    echo "2. 将私钥内容添加到GitHub仓库的Secrets中"
fi
echo "3. 测试SSH连接: ssh $DEPLOY_USER@$(hostname -I | awk '{print $1}')"
echo ""
echo "💡 安全提示:"
echo "- 定期更新系统和软件包"
echo "- 监控SSH访问日志"
echo "- 考虑使用SSH密钥轮换" 