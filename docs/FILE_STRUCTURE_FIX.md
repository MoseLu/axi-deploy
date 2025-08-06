# 文件结构修复指南

## 🚨 问题描述

诊断发现静态文件存在但路径结构不正确：

```
❌ 静态文件不存在: /srv/apps/axi-star-cloud/front/static/html/main-content.html
✅ 静态文件存在: /srv/apps/axi-star-cloud/front/html/main-content.html
```

## 🔍 问题分析

### 当前文件结构
```
/srv/apps/axi-star-cloud/front/
├── index.html
├── html/
│   └── main-content.html
├── css/
├── js/
└── public/
```

### 期望的文件结构
```
/srv/apps/axi-star-cloud/front/
├── index.html
├── static/
│   ├── html/
│   │   └── main-content.html
│   ├── css/
│   ├── js/
│   └── public/
└── ...
```

### 问题原因
Nginx配置期望静态文件在 `/static/` 目录下，但实际文件在根目录下。

## 🛠️ 解决方案

### 方案1：文件结构修复脚本（推荐）

在服务器上运行文件结构修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/fix-file-structure.sh
chmod +x fix-file-structure.sh
sudo ./fix-file-structure.sh
```

### 方案2：手动修复

如果无法下载脚本，手动执行：

```bash
# 1. 创建正确的目录结构
sudo mkdir -p /srv/apps/axi-star-cloud/front/static/html
sudo mkdir -p /srv/apps/axi-star-cloud/front/static/css
sudo mkdir -p /srv/apps/axi-star-cloud/front/static/js
sudo mkdir -p /srv/apps/axi-star-cloud/front/static/public

# 2. 移动文件到正确位置
sudo cp -r /srv/apps/axi-star-cloud/front/html/* /srv/apps/axi-star-cloud/front/static/html/
sudo cp -r /srv/apps/axi-star-cloud/front/css/* /srv/apps/axi-star-cloud/front/static/css/
sudo cp -r /srv/apps/axi-star-cloud/front/js/* /srv/apps/axi-star-cloud/front/static/js/
sudo cp -r /srv/apps/axi-star-cloud/front/public/* /srv/apps/axi-star-cloud/front/static/public/

# 3. 设置正确的权限
sudo chown -R deploy:deploy /srv/apps/axi-star-cloud/front/static
sudo chmod -R 755 /srv/apps/axi-star-cloud/front/static

# 4. 检查修复结果
ls -la /srv/apps/axi-star-cloud/front/static/html/

# 5. 测试静态文件访问
curl -I https://redamancy.com.cn/static/html/main-content.html

# 6. 重载Nginx
sudo systemctl reload nginx
```

## 🔧 配置说明

### Nginx配置路径映射

当前的Nginx配置：
```nginx
# 静态文件服务
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
}
```

这意味着：
- 访问 `/static/html/main-content.html`
- 实际文件路径 `/srv/apps/axi-star-cloud/front/html/main-content.html`

修复后：
- 访问 `/static/html/main-content.html`
- 实际文件路径 `/srv/apps/axi-star-cloud/front/static/html/main-content.html`

### 文件结构对比

**修复前**：
```
/srv/apps/axi-star-cloud/front/
├── index.html
├── html/main-content.html  ← 文件在这里
├── css/
├── js/
└── public/
```

**修复后**：
```
/srv/apps/axi-star-cloud/front/
├── index.html
├── static/
│   ├── html/main-content.html  ← 文件移动到这里
│   ├── css/
│   ├── js/
│   └── public/
└── ...
```

## 📋 验证修复

### 1. 检查文件结构
```bash
ls -la /srv/apps/axi-star-cloud/front/static/html/
```

### 2. 检查静态文件存在
```bash
ls -la /srv/apps/axi-star-cloud/front/static/html/main-content.html
```

### 3. 测试静态文件访问
```bash
curl -I https://redamancy.com.cn/static/html/main-content.html
```

### 4. 检查浏览器访问
- 打开 https://redamancy.com.cn/
- 检查开发者工具的网络面板
- 确认静态文件返回200状态码

## 🚀 重新部署

修复完成后，可以重新部署项目：

1. **推送代码到GitHub** - 触发自动部署
2. **运行文件结构修复脚本** - 确保文件在正确位置
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
   sudo chown -R deploy:deploy /srv/apps/axi-star-cloud/front/static
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

1. **正确的文件结构**: 前端文件部署到正确的static目录
2. **正确的文件权限**: 设置正确的文件所有者
3. **正确的Nginx配置**: 确保路径映射正确

### 最佳实践

1. **统一的文件结构**: 所有静态文件都在static目录下
2. **正确的文件权限**: 确保Nginx可以访问文件
3. **正确的Nginx配置**: 确保路径映射与实际文件路径匹配
4. **定期测试**: 定期运行测试脚本验证静态文件访问
