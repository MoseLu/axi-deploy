#!/bin/bash

# SSH密钥生成脚本
# 用于为部署创建SSH密钥对

set -e

# 默认参数
KEY_NAME="deploy_key"
KEY_TYPE="rsa"
KEY_BITS="4096"
EMAIL=""

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -n, --name KEY_NAME     密钥文件名 (默认: deploy_key)"
    echo "  -t, --type KEY_TYPE     密钥类型 (默认: rsa)"
    echo "  -b, --bits KEY_BITS     密钥位数 (默认: 4096)"
    echo "  -e, --email EMAIL       邮箱地址"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -n my_deploy_key -e user@example.com"
    echo "  $0 --type ed25519 --bits 256"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            KEY_NAME="$2"
            shift 2
            ;;
        -t|--type)
            KEY_TYPE="$2"
            shift 2
            ;;
        -b|--bits)
            KEY_BITS="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
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

# 检查必需参数
if [[ -z "$EMAIL" ]]; then
    echo "错误: 必须提供邮箱地址 (-e 或 --email)"
    exit 1
fi

echo "生成SSH密钥对..."
echo "密钥名称: $KEY_NAME"
echo "密钥类型: $KEY_TYPE"
echo "密钥位数: $KEY_BITS"
echo "邮箱地址: $EMAIL"
echo ""

# 创建.ssh目录
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 生成SSH密钥
ssh-keygen -t "$KEY_TYPE" -b "$KEY_BITS" -C "$EMAIL" -f ~/.ssh/"$KEY_NAME" -N ""

# 设置权限
chmod 600 ~/.ssh/"$KEY_NAME"
chmod 644 ~/.ssh/"$KEY_NAME.pub"

echo ""
echo "✅ SSH密钥生成成功!"
echo ""
echo "私钥文件: ~/.ssh/$KEY_NAME"
echo "公钥文件: ~/.ssh/$KEY_NAME.pub"
echo ""
echo "📋 私钥内容 (用于GitHub Secrets):"
echo "----------------------------------------"
cat ~/.ssh/"$KEY_NAME"
echo "----------------------------------------"
echo ""
echo "📋 公钥内容 (添加到服务器):"
echo "----------------------------------------"
cat ~/.ssh/"$KEY_NAME.pub"
echo "----------------------------------------"
echo ""
echo "🔧 下一步操作:"
echo "1. 将私钥内容添加到GitHub仓库的Secrets中"
echo "2. 将公钥添加到目标服务器的 ~/.ssh/authorized_keys"
echo "3. 获取服务器公钥指纹: ssh-keyscan -H YOUR_SERVER_IP"
echo ""
echo "💡 提示: 请妥善保管私钥，不要泄露给他人!" 