# 部署验证指南

## 概述

本文档提供了部署后的验证步骤，帮助诊断和解决403错误等问题。

## 验证步骤

### 1. 检查服务状态

```bash
# 检查systemd服务状态
sudo systemctl status star-cloud.service

# 检查服务日志
sudo journalctl -u star-cloud.service -f

# 检查端口监听
sudo netstat -tlnp | grep :8080
```

### 2. 检查文件权限

```bash
# 检查部署目录权限
ls -la /www/wwwroot/axi-star-cloud/

# 检查可执行文件权限
ls -la /www/wwwroot/axi-star-cloud/star-cloud-linux

# 检查uploads目录权限
ls -la /www/wwwroot/axi-star-cloud/uploads/
```

### 3. 检查Nginx配置

```bash
# 检查Nginx配置语法
sudo nginx -t

# 检查Nginx状态
sudo systemctl status nginx

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/error.log

# 查看Nginx访问日志
sudo tail -f /var/log/nginx/access.log
```

### 4. 测试API端点

```bash
# 测试健康检查端点
curl -v http://127.0.0.1:8080/health

# 测试API端点
curl -v http://127.0.0.1:8080/api/health

# 测试通过Nginx代理
curl -v https://redamancy.com.cn/health
```

### 5. 检查防火墙设置

```bash
# 检查防火墙状态
sudo ufw status

# 检查iptables规则
sudo iptables -L -n
```

## 常见问题解决

### 403错误解决方案

#### 1. 文件权限问题

```bash
# 修复文件权限
sudo chown -R www-data:www-data /www/wwwroot/axi-star-cloud/
sudo chmod -R 755 /www/wwwroot/axi-star-cloud/
sudo chmod +x /www/wwwroot/axi-star-cloud/star-cloud-linux
```

#### 2. Nginx配置问题

```bash
# 检查Nginx配置
sudo nginx -t

# 如果配置有问题，编辑配置文件
sudo nano /www/server/nginx/conf/vhost/redamancy.com.cn.conf

# 重新加载Nginx
sudo nginx -s reload
```

#### 3. SELinux问题（如果启用）

```bash
# 检查SELinux状态
sestatus

# 如果启用了SELinux，设置正确的上下文
sudo semanage fcontext -a -t httpd_exec_t "/www/wwwroot/axi-star-cloud/star-cloud-linux"
sudo restorecon -v /www/wwwroot/axi-star-cloud/star-cloud-linux
```

### 服务启动失败

#### 1. 检查服务配置

```bash
# 检查systemd服务文件
sudo cat /etc/systemd/system/star-cloud.service

# 重新加载systemd配置
sudo systemctl daemon-reload

# 重启服务
sudo systemctl restart star-cloud.service
```

#### 2. 检查端口冲突

```bash
# 检查8080端口是否被占用
sudo lsof -i :8080

# 如果有冲突，停止占用端口的进程
sudo pkill -f star-cloud-linux
```

### 数据库连接问题

```bash
# 检查数据库文件权限
ls -la /www/wwwroot/axi-star-cloud/config/

# 检查数据库文件是否存在
ls -la /www/wwwroot/axi-star-cloud/config/*.db
```

## 调试命令

### 实时监控

```bash
# 监控服务日志
sudo journalctl -u star-cloud.service -f

# 监控Nginx日志
sudo tail -f /var/log/nginx/error.log /var/log/nginx/access.log

# 监控系统资源
htop
```

### 网络诊断

```bash
# 测试本地连接
curl -v http://127.0.0.1:8080/health

# 测试域名解析
nslookup redamancy.com.cn

# 测试SSL证书
openssl s_client -connect redamancy.com.cn:443
```

## 部署检查清单

- [ ] Go服务是否正常启动
- [ ] 端口8080是否正常监听
- [ ] Nginx配置是否正确
- [ ] 文件权限是否正确
- [ ] 防火墙设置是否正确
- [ ] SSL证书是否正确（如果使用HTTPS）
- [ ] 域名解析是否正确
- [ ] 数据库连接是否正常

## 自动化验证脚本

```bash
#!/bin/bash
# deployment-check.sh

echo "🔍 开始部署验证..."

# 检查服务状态
echo "1. 检查服务状态..."
if sudo systemctl is-active --quiet star-cloud.service; then
    echo "✅ 服务运行正常"
else
    echo "❌ 服务未运行"
    sudo systemctl status star-cloud.service --no-pager --lines 5
fi

# 检查端口监听
echo "2. 检查端口监听..."
if sudo netstat -tlnp | grep :8080 > /dev/null; then
    echo "✅ 端口8080正常监听"
else
    echo "❌ 端口8080未监听"
fi

# 检查API响应
echo "3. 检查API响应..."
if curl -f -s http://127.0.0.1:8080/health > /dev/null; then
    echo "✅ API响应正常"
else
    echo "❌ API无响应"
fi

# 检查Nginx配置
echo "4. 检查Nginx配置..."
if sudo nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx配置正确"
else
    echo "❌ Nginx配置错误"
    sudo nginx -t
fi

# 检查文件权限
echo "5. 检查文件权限..."
if [ -x "/www/wwwroot/axi-star-cloud/star-cloud-linux" ]; then
    echo "✅ 可执行文件权限正确"
else
    echo "❌ 可执行文件权限错误"
fi

echo "🔍 验证完成"
```

## 联系支持

如果以上步骤都无法解决问题，请提供以下信息：

1. 服务状态日志：`sudo journalctl -u star-cloud.service --no-pager`
2. Nginx错误日志：`sudo tail -n 50 /var/log/nginx/error.log`
3. 系统资源使用情况：`htop` 截图
4. 网络连接测试结果：`curl -v https://redamancy.com.cn/health` 