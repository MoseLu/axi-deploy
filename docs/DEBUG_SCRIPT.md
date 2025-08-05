# Axi-Star-Cloud 服务器诊断脚本

## 使用方法

在服务器上运行以下脚本来诊断 axi-star-cloud 部署问题：

```bash
#!/bin/bash

echo "🔍 Axi-Star-Cloud 部署诊断脚本"
echo "=================================="

# 1. 检查部署目录
echo "1. 检查部署目录..."
if [ -d "/www/wwwroot/axi-star-cloud" ]; then
    echo "✅ 部署目录存在"
    ls -la /www/wwwroot/axi-star-cloud/
else
    echo "❌ 部署目录不存在"
    exit 1
fi

# 2. 检查可执行文件
echo ""
echo "2. 检查可执行文件..."
if [ -f "/www/wwwroot/axi-star-cloud/star-cloud-linux" ]; then
    echo "✅ 可执行文件存在"
    file /www/wwwroot/axi-star-cloud/star-cloud-linux
    ls -la /www/wwwroot/axi-star-cloud/star-cloud-linux
else
    echo "❌ 可执行文件不存在"
fi

# 3. 检查配置文件
echo ""
echo "3. 检查配置文件..."
if [ -f "/www/wwwroot/axi-star-cloud/backend/config/config.yaml" ]; then
    echo "✅ 配置文件存在"
    cat /www/wwwroot/axi-star-cloud/backend/config/config.yaml
else
    echo "❌ 配置文件不存在"
fi

# 4. 检查systemd服务
echo ""
echo "4. 检查systemd服务..."
if [ -f "/etc/systemd/system/star-cloud.service" ]; then
    echo "✅ 服务文件存在"
    cat /etc/systemd/system/star-cloud.service
else
    echo "❌ 服务文件不存在"
fi

# 5. 检查服务状态
echo ""
echo "5. 检查服务状态..."
sudo systemctl status star-cloud.service --no-pager --lines 10

# 6. 检查端口监听
echo ""
echo "6. 检查端口监听..."
netstat -tlnp | grep :8080 || ss -tlnp | grep :8080 || echo "端口8080未监听"

# 7. 检查进程
echo ""
echo "7. 检查进程..."
ps aux | grep star-cloud || echo "进程未找到"

# 8. 检查服务日志
echo ""
echo "8. 检查服务日志..."
sudo journalctl -u star-cloud.service --no-pager --lines 20

# 9. 手动测试服务启动
echo ""
echo "9. 手动测试服务启动..."
cd /www/wwwroot/axi-star-cloud/
timeout 10s ./star-cloud-linux || echo "手动启动失败"

# 10. 检查健康检查
echo ""
echo "10. 检查健康检查..."
curl -f -s http://127.0.0.1:8080/health && echo "✅ 健康检查通过" || echo "❌ 健康检查失败"

# 11. 检查Nginx配置
echo ""
echo "11. 检查Nginx配置..."
nginx -t
nginx -s reload

# 12. 检查Nginx错误日志
echo ""
echo "12. 检查Nginx错误日志..."
tail -n 20 /var/log/nginx/error.log

# 13. 检查网站访问
echo ""
echo "13. 检查网站访问..."
curl -I https://redamancy.com.cn/ 2>/dev/null || echo "网站访问失败"

echo ""
echo "🔍 诊断完成"
```

## 快速修复脚本

如果发现问题，可以运行以下修复脚本：

```bash
#!/bin/bash

echo "🔧 Axi-Star-Cloud 快速修复脚本"
echo "================================"

# 1. 停止服务
echo "1. 停止服务..."
sudo systemctl stop star-cloud.service 2>/dev/null || echo "服务已停止"

# 2. 修复权限
echo "2. 修复权限..."
sudo chown -R root:root /www/wwwroot/axi-star-cloud/
sudo chmod +x /www/wwwroot/axi-star-cloud/star-cloud-linux
sudo chmod 644 /www/wwwroot/axi-star-cloud/backend/config/*.yaml

# 3. 修复服务文件
echo "3. 修复服务文件..."
sudo sed -i 's|WorkingDirectory=/srv/apps/axi-star-cloud|WorkingDirectory=/www/wwwroot/axi-star-cloud|g' /etc/systemd/system/star-cloud.service
sudo sed -i 's|ExecStart=/srv/apps/axi-star-cloud/star-cloud-linux|ExecStart=/www/wwwroot/axi-star-cloud/star-cloud-linux|g' /etc/systemd/system/star-cloud.service

# 4. 重新加载服务
echo "4. 重新加载服务..."
sudo systemctl daemon-reload
sudo systemctl enable star-cloud.service
sudo systemctl restart star-cloud.service

# 5. 等待启动
echo "5. 等待服务启动..."
sleep 10

# 6. 检查结果
echo "6. 检查结果..."
sudo systemctl status star-cloud.service --no-pager --lines 5
curl -f -s http://127.0.0.1:8080/health && echo "✅ 修复成功" || echo "❌ 修复失败"

echo ""
echo "🔧 修复完成"
```

## 常见问题解决方案

### 问题1: 服务启动失败
```bash
# 检查配置文件
cat /www/wwwroot/axi-star-cloud/backend/config/config.yaml

# 手动启动测试
cd /www/wwwroot/axi-star-cloud/
./star-cloud-linux
```

### 问题2: 权限问题
```bash
# 修复权限
sudo chown -R root:root /www/wwwroot/axi-star-cloud/
sudo chmod +x /www/wwwroot/axi-star-cloud/star-cloud-linux
```

### 问题3: 端口被占用
```bash
# 检查端口占用
lsof -i :8080
# 杀死占用进程
sudo kill -9 $(lsof -t -i:8080)
```

### 问题4: 数据库问题
```bash
# 检查数据库文件
ls -la /www/wwwroot/axi-star-cloud/backend/*.db
# 修复数据库权限
sudo chmod 644 /www/wwwroot/axi-star-cloud/backend/*.db
```

## 使用说明

1. 将诊断脚本保存为 `debug.sh`
2. 给脚本添加执行权限：`chmod +x debug.sh`
3. 在服务器上运行：`./debug.sh`
4. 根据输出结果进行相应的修复

这个脚本会提供详细的诊断信息，帮助快速定位和解决问题。 