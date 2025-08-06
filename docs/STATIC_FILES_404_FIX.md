# 静态文件404问题修复指南

## 🚨 问题描述

Nginx配置修复成功后，主页面可以正常访问，但静态文件返回404错误：

```
🔗 测试静态文件...
  静态文件状态码: 404, 重定向次数: 0
```

## 🔍 问题分析

### 可能的原因

1. **文件路径不正确**: 静态文件不在预期的目录中
2. **部署路径错误**: 前端文件部署到了错误的路径
3. **Nginx配置路径不匹配**: Nginx配置中的路径与实际文件路径不匹配
4. **文件权限问题**: 文件存在但权限不正确

### 诊断步骤

1. **检查部署目录**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/
   ```

2. **检查静态文件**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/static/html/
   ```

3. **检查Nginx配置**:
   ```bash
   cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf
   ```

## 🛠️ 解决方案

### 方案1：静态文件路径检查脚本（推荐）

在服务器上运行静态文件路径检查脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/fix-static-files.sh
chmod +x fix-static-files.sh
sudo ./fix-static-files.sh
```

### 方案2：前端重新部署脚本

如果静态文件路径有问题，运行前端重新部署脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/redeploy-frontend.sh
chmod +x redeploy-frontend.sh
sudo ./redeploy-frontend.sh
```

### 方案3：手动修复

如果无法下载脚本，手动执行：

```bash
# 1. 检查当前部署状态
ls -la /srv/apps/axi-star-cloud/front/

# 2. 检查其他可能的部署路径
ls -la /www/wwwroot/axi-star-cloud/
ls -la /www/wwwroot/redamancy.com.cn/

# 3. 如果找到正确的前端文件，复制到正确位置
sudo mkdir -p /srv/apps/axi-star-cloud/front
sudo cp -r /www/wwwroot/axi-star-cloud/* /srv/apps/axi-star-cloud/front/
sudo chown -R deploy:deploy /srv/apps/axi-star-cloud/front

# 4. 检查部署结果
ls -la /srv/apps/axi-star-cloud/front/static/html/

# 5. 测试静态文件访问
curl -I https://redamancy.com.cn/static/html/main-content.html

# 6. 重载Nginx
sudo systemctl reload nginx
```

## 🔧 配置说明

### 正确的文件结构

前端文件应该部署在以下结构中：

```
/srv/apps/axi-star-cloud/front/
├── index.html
├── static/
│   ├── html/
│   │   ├── main-content.html
│   │   ├── header.html
│   │   └── login.html
│   ├── css/
│   ├── js/
│   └── public/
└── ...
```

### Nginx配置路径映射

Nginx配置中的静态文件路径映射：

```nginx
# 静态文件服务
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
}
```

这意味着：
- 访问 `/static/html/main-content.html` 
- 实际文件路径 `/srv/apps/axi-star-cloud/front/html/main-content.html`

## 📋 验证修复

### 1. 检查文件存在
```bash
ls -la /srv/apps/axi-star-cloud/front/static/html/main-content.html
```

### 2. 测试静态文件访问
```bash
curl -I https://redamancy.com.cn/static/html/main-content.html
```

### 3. 检查浏览器访问
- 打开 https://redamancy.com.cn/
- 检查开发者工具的网络面板
- 确认静态文件返回200状态码

## 🚀 重新部署

如果静态文件路径有问题，可以重新部署前端：

1. **推送代码到GitHub** - 触发自动部署
2. **运行重新部署脚本** - 确保文件部署到正确位置
3. **验证部署结果** - 检查静态文件是否可以正常访问

## 📞 故障排除

如果问题仍然存在：

1. **运行诊断脚本**：
   ```bash
   wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/fix-static-files.sh
   chmod +x fix-static-files.sh
   sudo ./fix-static-files.sh
   ```

2. **检查文件权限**：
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/static/html/
   sudo chown -R deploy:deploy /srv/apps/axi-star-cloud/front
   ```

3. **检查Nginx配置**：
   ```bash
   sudo nginx -t
   cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf
   ```

4. **检查Nginx日志**：
   ```bash
   sudo tail -f /var/log/nginx/error.log
   sudo tail -f /var/log/nginx/access.log
   ```

5. **手动测试文件访问**：
   ```bash
   curl -v https://redamancy.com.cn/static/html/main-content.html
   ```

## 🔄 长期维护

### 部署策略更新

在`axi-deploy/.github/workflows/universal_deploy.yml`中，确保：

1. **正确的部署路径**: 前端文件部署到 `/srv/apps/axi-star-cloud/front/`
2. **正确的文件权限**: 设置正确的文件所有者
3. **正确的Nginx配置**: 确保路径映射正确

### 最佳实践

1. **统一的部署路径**: 所有前端文件都部署到同一个路径
2. **正确的文件权限**: 确保Nginx可以访问文件
3. **正确的Nginx配置**: 确保路径映射与实际文件路径匹配
4. **定期测试**: 定期运行测试脚本验证静态文件访问
