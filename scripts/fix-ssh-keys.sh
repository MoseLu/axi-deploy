#!/bin/bash

# 快速修复SSH密钥配置脚本

set -e

DEPLOY_USER="deploy"
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiuGpYIBtTy2Z2o7t95puMcidVvToEPFmakIMYNdroDCfJEEDO1cpbK7GA22tnrqwtJh3nZsgAgO/YotNINZggox2Ts0zT96j2FwbqfA8usx2s7ZyobNA38HxeKED2RgMc88wYoin/dGPd3RpHdWjR1YX7rjzxYR+8NL0mPUILqdfpFWXN21wZGFCFM1Pj1x1CYmmzngpyL67C+uwvpGqmpSknE2KEHVJ75PWW8Lc1LJBGVR4QuJd93frs9hxFd1cMKn98ZFJyxs3651vwzOFgsAYC0ppLNMMOBsC0U04fJfhqrowez58PQdR7+HJEkHUVJf22bJBU9RjMcs4BNcHCWuGZBG1OctWvzHiwDeWVNfLtN6Vux2DrbRncckN7t3CqIxm+XRNF31LeHqnuvwXj1CCsu5BJ5xsDtje3kAfstg+MerooIwPZ0O6NKA4CYFnHvuCImV9Hbw3kV+VyuRvC379mgclobGuZck9XGSzvJSaj/af7RyiNu8SBNBqaP2/E538WgB/LbUJXDaSJ0SNXaTywkCsTP5WqrQ4QC11nV5ANGeByPaDdjLdCzZYEDcU9t1QnfVbvwPY/OFBfK1+fMAglKFvAVNocfO6lGv6qTFd733b6anRvpBC/VmEjb679fZXnJFJV3FAJ38WDJuR4ST4/9hQeoIxTdB0BJPTq2USM8== github-actions-deploy"

echo "🔧 开始修复SSH密钥配置..."

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo "错误: 此脚本需要root权限运行"
   echo "请使用: sudo $0"
   exit 1
fi

# 检查deploy用户是否存在
if ! id "$DEPLOY_USER" > /dev/null 2>&1; then
    echo "👤 创建deploy用户..."
    useradd -m -s /bin/bash "$DEPLOY_USER"
    echo "✅ deploy用户创建成功"
else
    echo "ℹ️  deploy用户已存在"
fi

# 创建SSH目录
echo "📁 配置SSH目录..."
mkdir -p /home/"$DEPLOY_USER"/.ssh
chown "$DEPLOY_USER:$DEPLOY_USER" /home/"$DEPLOY_USER"/.ssh
chmod 700 /home/"$DEPLOY_USER"/.ssh

# 创建authorized_keys文件
echo "🔑 配置authorized_keys..."
echo "$PUBLIC_KEY" > /home/"$DEPLOY_USER"/.ssh/authorized_keys
chown "$DEPLOY_USER:$DEPLOY_USER" /home/"$DEPLOY_USER"/.ssh/authorized_keys
chmod 600 /home/"$DEPLOY_USER"/.ssh/authorized_keys

echo "✅ SSH密钥配置完成"
echo ""
echo "📋 配置摘要:"
echo "- 用户: $DEPLOY_USER"
echo "- SSH目录: /home/$DEPLOY_USER/.ssh"
echo "- 公钥已添加到: /home/$DEPLOY_USER/.ssh/authorized_keys"
echo ""
echo "🔧 验证配置:"
echo "1. 检查文件权限: ls -la /home/$DEPLOY_USER/.ssh/"
echo "2. 检查公钥内容: cat /home/$DEPLOY_USER/.ssh/authorized_keys"
echo "3. 测试SSH连接: ssh -i ~/.ssh/github_actions_key $DEPLOY_USER@$(hostname -I | awk '{print $1}')"
echo ""
echo "💡 如果连接仍然失败，请检查:"
echo "- SSH服务状态: systemctl status ssh"
echo "- SSH日志: tail -f /var/log/auth.log" 