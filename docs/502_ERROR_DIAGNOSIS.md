# 502错误诊断和修复指南

## 🚨 问题描述

在部署过程中遇到502错误：

```
HTTPS测试结果: 502
🚨 网站测试失败 - HTTPS返回状态码: 502
```

**502错误含义：**
- 502 Bad Gateway：网关错误
- 表示Nginx作为反向代理无法从后端服务器获得有效响应
- 通常是后端服务未启动或配置问题

## 🔍 诊断步骤

### 1. 检查后端服务状态

```bash
# 检查PM2进程
pm2 list

# 检查系统进程
pgrep -f axi-project-dashboard

# 检查端口占用
netstat -tlnp | grep :8090
```

### 2. 检查Nginx配置

```bash
# 检查Nginx语法
nginx -t

# 检查项目配置文件
cat /www/server/nginx/conf/conf.d/redamancy/route-axi-project-dashboard.conf

# 检查Nginx状态
systemctl status nginx
```

### 3. 检查本地连接

```bash
# 测试本地8090端口
curl -f http://localhost:8090/health

# 测试本地8080端口
curl -f http://localhost:8080/health
```

### 4. 检查日志文件

```bash
# Nginx错误日志
tail -n 20 /var/log/nginx/error.log

# Nginx访问日志
tail -n 10 /var/log/nginx/access.log

# 系统日志
journalctl -u nginx --no-pager -n 20
```

## 🔧 常见原因和修复

### 1. 后端服务未启动

**症状：**
- PM2进程列表为空
- 端口8090未被占用
- 本地连接测试失败

**修复方法：**
```bash
# 进入项目目录
cd /srv/apps/axi-project-dashboard

# 检查项目文件
ls -la

# 启动服务
pm2 start ecosystem.config.js

# 检查启动状态
pm2 status
```

### 2. Nginx配置错误

**症状：**
- Nginx配置语法错误
- 项目配置文件不存在或内容错误
- Nginx服务状态异常

**修复方法：**
```bash
# 检查配置文件语法
nginx -t

# 重新生成配置文件
# 通过GitHub Actions重新部署

# 重载Nginx配置
systemctl reload nginx
```

### 3. 端口冲突

**症状：**
- 端口被其他进程占用
- 服务启动失败

**修复方法：**
```bash
# 检查端口占用
netstat -tlnp | grep :8090

# 停止冲突进程
pm2 stop dashboard-backend
pm2 delete dashboard-backend

# 重新启动服务
pm2 start ecosystem.config.js
```

### 4. 权限问题

**症状：**
- 无法读取日志文件
- 服务启动失败

**修复方法：**
```bash
# 检查文件权限
ls -la /srv/apps/axi-project-dashboard/

# 修复权限
chmod -R 755 /srv/apps/axi-project-dashboard/
chown -R deploy:deploy /srv/apps/axi-project-dashboard/
```

### 5. 依赖问题

**症状：**
- 服务启动时出现错误
- 模块加载失败

**修复方法：**
```bash
# 进入项目目录
cd /srv/apps/axi-project-dashboard

# 重新安装依赖
pnpm install --force

# 重新构建项目
pnpm build
```

## 🛠️ 自动化诊断工具

### 诊断工作流

创建了 `diagnose-502.yml` 工作流，可以自动诊断502错误：

```yaml
# 手动触发诊断
gh workflow run diagnose-502.yml \
  --field project=axi-project-dashboard \
  --field server_host=redamancy.com.cn \
  --field server_user=deploy \
  --field server_key="$SSH_KEY" \
  --field server_port=22
```

### 诊断内容

诊断工作流会检查：

1. **系统基本信息**：主机名、系统版本、用户信息
2. **网络连接**：本地回环、外网连接、域名解析
3. **端口占用**：80、443、8090、8080端口
4. **Nginx状态**：进程、服务状态、配置语法
5. **项目配置**：配置文件存在性和内容
6. **项目部署**：目录存在性和文件数量
7. **后端服务**：PM2进程、系统进程、端口占用
8. **日志文件**：访问日志、错误日志、系统日志
9. **本地连接**：8090、8080端口测试
10. **防火墙**：防火墙状态、iptables规则
11. **SSL证书**：证书有效期检查
12. **网站访问**：HTTP和HTTPS访问测试

## 📊 修复效果

### 修复前
- 502错误导致工作流直接退出
- 缺乏详细的诊断信息
- 难以定位具体问题

### 修复后
- 增加重试机制（3次尝试）
- 提供详细的诊断信息
- 继续执行后续步骤而不是直接退出
- 自动诊断工具提供全面检查

## 🚀 最佳实践

### 1. 部署前检查

```bash
# 检查服务器状态
systemctl status nginx
pm2 status

# 检查端口占用
netstat -tlnp | grep -E ":(80|443|8090)"

# 检查项目目录
ls -la /srv/apps/axi-project-dashboard/
```

### 2. 部署后验证

```bash
# 等待服务启动
sleep 15

# 测试本地连接
curl -f http://localhost:8090/health

# 测试外部访问
curl -I https://redamancy.com.cn/project-dashboard/api/health
```

### 3. 监控和告警

- 设置服务健康检查
- 监控端口占用情况
- 配置日志监控
- 设置自动重启机制

## 📝 相关文件

- `test-website.yml`: 修复后的网站测试工作流
- `diagnose-502.yml`: 502错误诊断工作流
- `start-service.yml`: 启动服务工作流
- `configure-nginx.yml`: Nginx配置工作流
- `502_ERROR_DIAGNOSIS.md`: 本文档

## ✅ 验证清单

- [ ] 后端服务正常启动
- [ ] Nginx配置正确
- [ ] 端口无冲突
- [ ] 权限设置正确
- [ ] 依赖安装完整
- [ ] 本地连接正常
- [ ] 外部访问正常
- [ ] 日志无错误

## 🔧 故障排除

### 常见问题

1. **服务启动失败**
   - 检查项目文件完整性
   - 验证依赖安装
   - 查看启动日志

2. **配置错误**
   - 检查Nginx语法
   - 验证配置文件路径
   - 确认代理设置

3. **网络问题**
   - 检查防火墙设置
   - 验证端口开放
   - 测试网络连接

### 调试技巧

1. 使用诊断工作流进行自动检查
2. 查看详细的错误日志
3. 逐步验证每个组件
4. 使用本地测试隔离问题
