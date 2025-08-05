# Axi-Star-Cloud 部署调试指南

## 问题概述

axi-star-cloud 部署后出现 403 错误，而 axi-docs 部署正常。本指南帮助诊断和解决这个问题。

## 正确的部署方式

### 1. 使用通用部署工作流

**不要使用特定项目的部署配置**，应该使用通用的部署方式：

```yaml
# 正确的做法：使用 universal_deploy.yml
trigger-deploy:
  needs: build
  runs-on: ubuntu-latest
  steps:
    - name: 触发部署
      uses: actions/github-script@v7
      with:
        github-token: ${{ secrets.DEPLOY_CENTER_PAT }}
        script: |
          const { data: response } = await github.rest.actions.createWorkflowDispatch({
            owner: 'MoseLu',
            repo: 'axi-deploy',
            workflow_id: 'universal_deploy.yml',
            ref: 'master',
            inputs: {
              project: '${{ github.event.repository.name }}',
              source_repo: '${{ github.repository }}',
              run_id: '${{ needs.build.outputs.run_id }}',
              deploy_type: 'backend',
              nginx_config: '...',
              test_url: 'https://example.com/',
              start_cmd: '...'
            }
          });
```

### 2. 项目类型差异

| 项目 | 类型 | 部署方式 | 服务管理 |
|------|------|----------|----------|
| axi-docs | 静态网站 | 直接部署到 Nginx | 无需后台服务 |
| axi-star-cloud | Go 后端 + 前端 | 需要 systemd 服务 | 需要后台进程 |

### 3. 部署路径问题

**问题**: systemd 服务配置与部署路径不匹配
- 部署路径: `/www/wwwroot/axi-star-cloud`
- 原服务配置: `/srv/apps/axi-star-cloud`

**解决方案**: 已修复 systemd 服务文件路径

### 4. Nginx 配置差异

**axi-docs** (静态网站):
```nginx
location /docs/ {
    alias /www/wwwroot/axi-docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
}
```

**axi-star-cloud** (动态应用):
```nginx
# 静态文件服务
location / {
    root /www/wwwroot/axi-star-cloud;
    try_files $uri $uri/ /index.html;
}

# API代理
location /api/ {
    proxy_pass http://127.0.0.1:8080/;
    # ... 代理设置
}
```

## 调试步骤

### 1. 检查服务状态

```bash
# 检查 systemd 服务状态
sudo systemctl status star-cloud.service

# 查看服务日志
sudo journalctl -u star-cloud.service -f

# 检查端口监听
netstat -tlnp | grep :8080
ss -tlnp | grep :8080
```

### 2. 检查文件权限

```bash
# 检查部署文件
ls -la /www/wwwroot/axi-star-cloud/

# 检查可执行文件
file /www/wwwroot/axi-star-cloud/star-cloud-linux

# 检查配置文件
ls -la /www/wwwroot/axi-star-cloud/backend/config/
```

### 3. 手动测试服务

```bash
# 切换到部署目录
cd /www/wwwroot/axi-star-cloud/

# 手动启动服务
./star-cloud-linux

# 测试健康检查
curl http://127.0.0.1:8080/health
```

### 4. 检查 Nginx 配置

```bash
# 检查 Nginx 配置语法
nginx -t

# 检查 Nginx 错误日志
tail -f /var/log/nginx/error.log

# 检查 Nginx 访问日志
tail -f /var/log/nginx/access.log
```

### 5. 检查防火墙和端口

```bash
# 检查防火墙状态
sudo ufw status
sudo iptables -L

# 检查端口是否被占用
lsof -i :8080
```

## 常见问题及解决方案

### 问题 1: 服务启动失败

**症状**: systemd 服务状态为 failed
**原因**: 路径不匹配、权限问题、配置文件错误

**解决方案**:
```bash
# 修复路径
sed -i 's|WorkingDirectory=/srv/apps/axi-star-cloud|WorkingDirectory=/www/wwwroot/axi-star-cloud|g' /etc/systemd/system/star-cloud.service
sed -i 's|ExecStart=/srv/apps/axi-star-cloud/star-cloud-linux|ExecStart=/www/wwwroot/axi-star-cloud/star-cloud-linux|g' /etc/systemd/system/star-cloud.service

# 重新加载服务
sudo systemctl daemon-reload
sudo systemctl restart star-cloud.service
```

### 问题 2: 端口未监听

**症状**: 8080 端口未监听
**原因**: 服务未启动、配置文件错误

**解决方案**:
```bash
# 检查配置文件
cat /www/wwwroot/axi-star-cloud/backend/config/config.yaml

# 手动启动测试
cd /www/wwwroot/axi-star-cloud/
./star-cloud-linux
```

### 问题 3: Nginx 403 错误

**症状**: 网站返回 403 Forbidden
**原因**: 文件权限、路径配置、后端服务未启动

**解决方案**:
```bash
# 检查文件权限
sudo chown -R www-data:www-data /www/wwwroot/axi-star-cloud/
sudo chmod -R 755 /www/wwwroot/axi-star-cloud/

# 检查 Nginx 配置
nginx -t
nginx -s reload
```

### 问题 4: 数据库连接失败

**症状**: 服务启动时数据库连接错误
**原因**: SQLite 文件权限、路径问题

**解决方案**:
```bash
# 检查数据库文件
ls -la /www/wwwroot/axi-star-cloud/backend/

# 修复权限
sudo chown -R root:root /www/wwwroot/axi-star-cloud/backend/
sudo chmod 644 /www/wwwroot/axi-star-cloud/backend/*.db
```

## 部署验证清单

### 部署前检查
- [ ] Go 应用编译成功
- [ ] 配置文件存在且正确
- [ ] systemd 服务文件路径正确

### 部署后检查
- [ ] 文件解压到正确位置
- [ ] 可执行文件权限正确
- [ ] systemd 服务启动成功
- [ ] 8080 端口监听正常
- [ ] 健康检查端点响应正常
- [ ] Nginx 配置正确
- [ ] 静态文件可访问
- [ ] API 代理工作正常

### 最终验证
- [ ] 网站首页可访问
- [ ] 登录功能正常
- [ ] 文件上传功能正常
- [ ] API 接口响应正常

## 自动化调试脚本

```bash
#!/bin/bash
# 部署后自动诊断脚本

echo "🔍 开始诊断 axi-star-cloud 部署..."

# 1. 检查服务状态
echo "1. 检查 systemd 服务状态"
sudo systemctl status star-cloud.service --no-pager --lines 5

# 2. 检查端口监听
echo "2. 检查端口监听"
netstat -tlnp | grep :8080 || ss -tlnp | grep :8080

# 3. 测试健康检查
echo "3. 测试健康检查"
curl -f -s http://127.0.0.1:8080/health && echo "✅ 健康检查通过" || echo "❌ 健康检查失败"

# 4. 检查文件权限
echo "4. 检查文件权限"
ls -la /www/wwwroot/axi-star-cloud/star-cloud-linux

# 5. 检查 Nginx 配置
echo "5. 检查 Nginx 配置"
nginx -t

# 6. 测试网站访问
echo "6. 测试网站访问"
curl -I https://redamancy.com.cn/

echo "🔍 诊断完成"
```

## 联系支持

如果问题仍然存在，请提供以下信息：

1. 部署日志输出
2. systemd 服务状态
3. Nginx 错误日志
4. 健康检查响应
5. 端口监听状态

这些信息将帮助快速定位和解决问题。 