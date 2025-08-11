# 目录结构修复指南

## 🚨 问题描述

在部署过程中发现目录结构错误：

```
✅ 项目目录存在: /srv/apps/axi-project-dashboard
- 目录内容:
drwxr-xr-x 4 admin     118 4096 Aug 11 14:56 dist-axi-project-dashboard
```

**问题原因：**
- 构建产物包含额外的 `dist-axi-project-dashboard` 目录层级
- 实际项目文件在 `dist-axi-project-dashboard` 子目录中
- 导致 PM2 无法找到 `ecosystem.config.js` 等关键文件
- 后端服务启动失败，返回502错误

## 🔧 修复方案

### 1. 自动目录结构修复

在部署工作流中添加了 `修复目录结构` 步骤：

```yaml
- name: 修复目录结构
  uses: appleboy/ssh-action@v1.0.3
  with:
    script: |
      # 检查是否存在额外的dist-目录
      DIST_SUBDIR="$DEPLOY_PATH/dist-$PROJECT"
      if [ -d "$DIST_SUBDIR" ]; then
        # 移动dist-目录下的所有内容到项目根目录
        mv "$DIST_SUBDIR"/* "$DEPLOY_PATH/"
        # 删除空的dist-目录
        rmdir "$DIST_SUBDIR"
      fi
```

### 2. 修复逻辑

1. **检测额外目录**：检查是否存在 `dist-$PROJECT` 子目录
2. **验证内容**：确认子目录包含正确的项目文件
3. **移动文件**：将子目录内容移动到项目根目录
4. **清理结构**：删除空的子目录
5. **设置权限**：确保文件权限正确

### 3. 预期目录结构

**修复前：**
```
/srv/apps/axi-project-dashboard/
└── dist-axi-project-dashboard/
    ├── backend/
    ├── frontend/
    ├── package.json
    ├── ecosystem.config.js
    └── start.sh
```

**修复后：**
```
/srv/apps/axi-project-dashboard/
├── backend/
├── frontend/
├── package.json
├── ecosystem.config.js
└── start.sh
```

## 📊 修复效果

### 修复前
- 项目文件在 `dist-axi-project-dashboard` 子目录中
- PM2 无法找到 `ecosystem.config.js`
- 后端服务启动失败
- 502错误：后端服务未响应

### 修复后
- 项目文件直接在项目根目录中
- PM2 可以正常找到配置文件
- 后端服务正常启动
- 网站访问正常

## 🔍 验证方法

### 1. 检查目录结构

```bash
# 检查项目目录
ls -la /srv/apps/axi-project-dashboard/

# 检查关键文件
ls -la /srv/apps/axi-project-dashboard/ecosystem.config.js
ls -la /srv/apps/axi-project-dashboard/package.json
ls -la /srv/apps/axi-project-dashboard/backend/
ls -la /srv/apps/axi-project-dashboard/frontend/
```

### 2. 检查服务状态

```bash
# 检查PM2进程
pm2 list

# 检查端口占用
netstat -tlnp | grep :8090

# 测试本地连接
curl -f http://localhost:8090/health
```

### 3. 检查网站访问

```bash
# 测试外部访问
curl -I https://redamancy.com.cn/project-dashboard/api/health
```

## 🚀 最佳实践

### 1. 构建产物标准化

确保构建产物不包含额外的目录层级：

```bash
# 正确的构建产物结构
dist-axi-project-dashboard/
├── backend/
├── frontend/
├── package.json
├── ecosystem.config.js
└── start.sh

# 而不是
dist-axi-project-dashboard/
└── dist-axi-project-dashboard/
    ├── backend/
    ├── frontend/
    ├── package.json
    ├── ecosystem.config.js
    └── start.sh
```

### 2. 部署前检查

在部署前检查构建产物结构：

```bash
# 检查构建产物
ls -la dist-axi-project-dashboard/

# 检查是否有多余的目录层级
find dist-axi-project-dashboard/ -type d -name "dist-*"
```

### 3. 自动化修复

依赖部署工作流的自动修复功能，无需手动干预。

## 📝 相关文件

- `deploy-project.yml`: 修复后的部署工作流
- `start-service.yml`: 启动服务工作流
- `test-website.yml`: 网站测试工作流
- `DIRECTORY_STRUCTURE_FIX.md`: 本文档

## ✅ 验证清单

- [ ] 项目文件在正确位置
- [ ] 没有多余的目录层级
- [ ] 关键文件存在且可访问
- [ ] 文件权限正确
- [ ] PM2 可以找到配置文件
- [ ] 后端服务正常启动
- [ ] 端口8090被占用
- [ ] 本地连接测试通过
- [ ] 外部访问测试通过

## 🔧 故障排除

### 常见问题

1. **目录结构仍然错误**
   - 检查构建产物是否包含额外的目录层级
   - 验证修复脚本是否正确执行
   - 查看部署日志中的错误信息

2. **文件权限问题**
   - 检查文件所有者是否为 deploy
   - 验证文件权限是否为 755
   - 确保启动脚本可执行

3. **服务启动失败**
   - 检查 ecosystem.config.js 是否存在
   - 验证 package.json 是否完整
   - 查看 PM2 启动日志

### 调试技巧

1. 使用诊断工作流检查目录结构
2. 查看部署日志中的修复步骤
3. 手动验证文件位置和权限
4. 测试服务启动和连接
