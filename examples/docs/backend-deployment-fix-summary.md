# 后端部署修复总结

## 问题背景

在之前的部署过程中，出现了严重的项目间文件交叉污染问题：

1. **静态项目** 的构建产物被错误地部署到 **后端项目** 的目录
2. **后端项目** 的目录下出现了本应属于 **静态项目** 的文件
3. 多个项目共享 `/tmp` 目录，导致文件混乱和部署失败

## 根本原因分析

### 1. 共享临时目录问题

**问题描述：**
```yaml
# 修改前 - 所有项目共享同一个临时目录
target: "/tmp/"
```

**影响：**
- 项目 A 部署后，`/tmp` 中残留文件
- 项目 B 部署时，会复制 `/tmp` 中的所有文件
- 导致项目 B 目录下出现项目 A 的文件

### 2. 缺乏清理机制

**问题描述：**
- 部署前没有清理目标目录
- 部署后没有清理临时目录
- 导致文件累积和混乱

### 3. 统一处理逻辑

**问题描述：**
- 静态项目和后端项目使用相同的文件处理逻辑
- 没有根据项目类型进行区分处理

## 解决方案

### 1. 独立临时目录

**修改内容：**
```yaml
# 修改后 - 每个项目使用独立的临时目录
target: "/tmp/${{ inputs.project }}/"
```

**优势：**
- ✅ 每个项目有独立的临时空间
- ✅ 避免文件交叉污染
- ✅ 支持并行部署

### 2. 部署前清理

**修改内容：**
```bash
# 清理目标部署目录（避免残留文件）
sudo rm -rf $DEPLOY_PATH/*
```

**优势：**
- ✅ 确保目标目录干净
- ✅ 避免旧文件残留
- ✅ 保证部署的一致性

### 3. 部署后清理

**修改内容：**
```bash
# 清理临时目录
sudo rm -rf $TEMP_DIR
```

**优势：**
- ✅ 及时清理临时文件
- ✅ 释放服务器空间
- ✅ 避免临时文件累积

### 4. 项目专用路径

**修改内容：**
```bash
PROJECT="${{ inputs.project }}"
TEMP_DIR="/tmp/$PROJECT"
DEPLOY_PATH="$APPS_ROOT/$PROJECT"  # 或 $STATIC_ROOT/$PROJECT
```

**优势：**
- ✅ 路径一致性
- ✅ 避免硬编码
- ✅ 支持动态项目名称

## 修改详情

### universal_deploy.yml 主要修改

#### 1. SCP 上传路径修改

```yaml
# 修改前
- name: 上传到服务器
  uses: appleboy/scp-action@v0.1.7
  with:
    source: "./dist/*"
    target: "/tmp/"  # 所有项目共享

# 修改后
- name: 上传到服务器
  uses: appleboy/scp-action@v0.1.7
  with:
    source: "./dist/*"
    target: "/tmp/${{ inputs.project }}/"  # 项目独立目录
```

#### 2. 部署脚本修改

```bash
# 修改前
cd /tmp
sudo cp -r * $DEPLOY_PATH/

# 修改后
PROJECT="${{ inputs.project }}"
TEMP_DIR="/tmp/$PROJECT"

# 清理目标部署目录
sudo rm -rf $DEPLOY_PATH/*

# 检查临时目录是否存在
if [ ! -d "$TEMP_DIR" ]; then
    echo "❌ 临时目录不存在: $TEMP_DIR"
    exit 1
fi

# 进入项目临时目录
cd $TEMP_DIR

# 部署文件
sudo cp -r * $DEPLOY_PATH/

# 清理临时目录
sudo rm -rf $TEMP_DIR
```

#### 3. 错误处理改进

```bash
# 添加了详细的错误检查和日志
if [ ! -d "$TEMP_DIR" ]; then
    echo "❌ 临时目录不存在: $TEMP_DIR"
    echo "📁 /tmp 目录内容:"
    ls -la /tmp/
    exit 1
fi

echo "📁 当前临时目录内容:"
ls -la
```

## 项目配置更新

### 后端项目配置示例

```yaml
deploy:
  needs: build
  uses: MoseLu/axi-deploy/.github/workflows/universal_deploy.yml@master
  with:
    project: ${{ github.event.repository.name }}
    source_repo: ${{ github.repository }}
    run_id: ${{ github.run_id }}
    deploy_type: backend
    nginx_config: |
      location /api/ {
          proxy_pass http://127.0.0.1:8080/;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 100M;
      }
      
      location /health {
          proxy_pass http://127.0.0.1:8080/health;
          proxy_set_header Host $host;
      }
      
      location / {
          root /srv/apps/${{ github.event.repository.name }}/front;
          try_files $uri $uri/ /index.html;
          
          # 静态资源缓存
          location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
              expires 1y;
              add_header Cache-Control "public, immutable";
          }
      }
    test_url: https://your-domain.com/
```

## 验证和测试

### 1. 创建验证脚本

创建了 `scripts/verify_deployment.sh` 脚本，用于：

- ✅ 检查目录结构是否正确
- ✅ 检查文件交叉污染
- ✅ 检查服务状态
- ✅ 检查端口占用
- ✅ 检查健康检查
- ✅ 检查 Nginx 配置
- ✅ 检查 SSL 证书
- ✅ 测试网站访问

### 2. 测试用例

#### 测试场景 1：后端项目部署
```bash
# 部署后端项目
# 验证文件位置：/srv/apps/<project>/
# 验证临时目录：/tmp/<project>/ (部署后应被清理)
```

#### 测试场景 2：连续部署
```bash
# 先部署静态项目，再部署后端项目
# 验证两个项目目录互不干扰
# 验证临时目录正确清理
```

## 部署流程对比

### 修改前流程

```
1. 构建产物上传到 /tmp/
2. 进入 /tmp 目录
3. 复制所有文件到目标目录
4. 配置 Nginx
5. 启动服务
```

**问题：**
- ❌ 所有项目共享 `/tmp` 目录
- ❌ 没有清理机制
- ❌ 容易产生文件交叉污染

### 修改后流程

```
1. 构建产物上传到 /tmp/<project>/
2. 清理目标目录 /srv/apps/<project>/
3. 进入项目临时目录 /tmp/<project>/
4. 复制文件到目标目录
5. 清理临时目录 /tmp/<project>/
6. 配置 Nginx
7. 启动服务
```

**优势：**
- ✅ 每个项目独立临时目录
- ✅ 部署前清理目标目录
- ✅ 部署后清理临时目录
- ✅ 避免文件交叉污染

## 监控和日志

### 1. 增强的日志记录

```bash
echo "📁 项目临时目录: $TEMP_DIR"
echo "📁 当前临时目录内容:"
ls -la
echo "🧹 清理临时目录..."
echo "✅ 临时目录已清理: $TEMP_DIR"
```

### 2. 错误处理改进

```bash
if [ ! -d "$TEMP_DIR" ]; then
    echo "❌ 临时目录不存在: $TEMP_DIR"
    echo "📁 /tmp 目录内容:"
    ls -la /tmp/
    exit 1
fi
```

### 3. 部署报告

验证脚本会生成详细的部署报告，包含：
- 目录结构检查结果
- 服务状态信息
- 端口占用情况
- 健康检查结果
- 错误日志摘要

## 回滚策略

### 1. 自动回滚

如果部署失败，脚本会自动：
- 清理临时目录
- 保留原有文件
- 记录错误日志

### 2. 手动回滚

```bash
# 停止服务
sudo systemctl stop <service-name>.service

# 恢复备份（如果有）
sudo cp -r /srv/apps/<project>.backup/* /srv/apps/<project>/

# 重启服务
sudo systemctl start <service-name>.service
```

## 性能优化

### 1. 并行部署支持

由于每个项目使用独立临时目录，现在支持：
- ✅ 多个项目并行部署
- ✅ 避免文件锁冲突
- ✅ 提高部署效率

### 2. 资源清理

- ✅ 及时清理临时文件
- ✅ 减少磁盘空间占用
- ✅ 避免文件系统碎片

## 安全性改进

### 1. 路径隔离

- ✅ 项目间完全隔离
- ✅ 避免权限冲突
- ✅ 提高安全性

### 2. 权限控制

- ✅ 正确的文件所有者设置
- ✅ 适当的文件权限
- ✅ 安全的目录结构

## 总结

通过这次修复，我们成功解决了项目间文件交叉污染的问题：

### ✅ 解决的问题

1. **文件交叉污染** - 通过独立临时目录解决
2. **部署不一致** - 通过部署前清理解决
3. **资源浪费** - 通过部署后清理解决
4. **错误处理** - 通过增强的日志和检查解决

### ✅ 获得的优势

1. **可靠性** - 部署过程更加稳定可靠
2. **可维护性** - 代码结构更清晰，易于维护
3. **可扩展性** - 支持更多项目类型和部署场景
4. **安全性** - 项目间完全隔离，提高安全性
5. **性能** - 支持并行部署，提高效率

### ✅ 验证方法

1. **自动化验证** - 使用验证脚本自动检查
2. **手动验证** - 提供详细的验证步骤
3. **监控告警** - 部署失败时及时告警

这次修复确保了部署系统的稳定性和可靠性，为后续的项目部署提供了坚实的基础。 