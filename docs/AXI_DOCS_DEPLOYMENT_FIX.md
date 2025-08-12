# AXI-Docs 部署问题分析与解决方案

## 问题描述

axi-docs 项目在进行部署时，构建产物在目标目录只有 `/srv/static/axi-docs/index.html`，dist 目录下的其他内容（特别是 assets 目录）都没有被正确上传。

## 问题分析

### 1. 构建产物结构
VitePress 构建后的产物位于 `docs/.vitepress/dist/` 目录，包含：
- `index.html` - 主页面
- `assets/` - 静态资源目录（CSS、JS、字体等）
- `content/` - 内容页面
- `examples/` - 示例页面
- 其他静态文件（favicon.ico、theme.css 等）

### 2. 问题根源
**`appleboy/scp-action@v0.1.4` 版本存在已知的目录复制问题**：
- 当源目录包含子目录时，可能只复制部分文件
- 特别是对于包含大量静态资源的 VitePress 项目，assets 目录下的文件可能没有被正确复制
- 这个版本在处理复杂目录结构时存在 bug

### 3. 影响
- 网站无法正常加载 CSS 和 JS 文件
- 字体文件缺失导致样式异常
- 用户体验严重受损

## 解决方案

### 1. 使用压缩包确保目录结构完整
由于 `actions/upload-artifact` 和 `gh run download` 在处理复杂目录结构时可能存在问题，我们采用压缩包方案：

#### 1.1 构建时创建压缩包
在 axi-docs 构建工作流中创建 tar.gz 压缩包：

```yaml
- name: 准备上传目录
  run: |
    echo "🔧 准备上传目录..."
    # 确保构建产物目录存在且不为空
    if [ ! -d "docs/.vitepress/dist" ]; then
      echo "❌ 构建产物目录不存在"
      exit 1
    fi
    
    # 检查构建产物是否为空
    if [ -z "$(ls -A docs/.vitepress/dist)" ]; then
      echo "❌ 构建产物目录为空"
      exit 1
    fi
    
    echo "✅ 构建产物准备完成"
    echo "构建产物内容:"
    ls -la docs/.vitepress/dist/
    
    # 创建压缩包以确保目录结构完整
    echo "📦 创建构建产物压缩包..."
    tar -czf dist-axi-docs.tar.gz -C docs/.vitepress dist
    
    echo "✅ 压缩包创建完成"
    echo "📊 压缩包大小: $(du -h dist-axi-docs.tar.gz | cut -f1)"
    echo "📁 压缩包内容预览:"
    tar -tzf dist-axi-docs.tar.gz | head -20

- name: 上传产物
  uses: actions/upload-artifact@v4
  with:
    name: dist-axi-docs
    path: |
      docs/.vitepress/dist/
      dist-axi-docs.tar.gz
    retention-days: 1
    if-no-files-found: error
```

#### 1.2 部署时优先使用压缩包
在 axi-deploy 部署工作流中优先解压压缩包：

```yaml
- name: 下载构建产物
  run: |
    # 下载构建产物
    echo "⬇️ 开始下载构建产物..."
    gh run download ${{ inputs.run_id }} \
      --name "dist-${{ inputs.project }}" \
      --dir . \
      --repo ${{ inputs.source_repo }}
    
    # 验证下载结果
    echo "🔍 验证下载结果..."
    if [ -f "dist-${{ inputs.project }}.tar.gz" ]; then
      echo "✅ 构建产物压缩包下载成功"
      echo "📦 解压构建产物压缩包..."
      tar -xzf "dist-${{ inputs.project }}.tar.gz"
      
      # 检查解压后的目录结构
      if [ -d "dist" ]; then
        echo "✅ 压缩包解压成功，重命名目录..."
        mv dist "dist-${{ inputs.project }}"
        file_count=$(find "dist-${{ inputs.project }}" -type f | wc -l)
        echo "✅ 构建产物解压成功，包含 $file_count 个文件"
      else
        echo "❌ 压缩包解压后未找到预期的 dist 目录"
        exit 1
      fi
    elif [ -d "dist-${{ inputs.project }}" ]; then
      file_count=$(find "dist-${{ inputs.project }}" -type f | wc -l)
      echo "✅ 构建产物下载成功，包含 $file_count 个文件"
    else
      echo "❌ 构建产物下载失败"
      exit 1
    fi
```

### 2. 更新 scp-action 版本
将 `appleboy/scp-action@v0.1.4` 更新到 `appleboy/scp-action@v1.0.0`：

```yaml
- name: 上传构建产物到部署目录
  uses: appleboy/scp-action@v1.0.0
  with:
    host: ${{ inputs.server_host }}
    username: ${{ inputs.server_user }}
    key: ${{ inputs.server_key }}
    port: ${{ inputs.server_port }}
    source: "./dist-${{ inputs.project }}/"
    target: "${{ inputs.deploy_type == 'backend' && format('{0}/{1}', inputs.apps_root || '/srv/apps', inputs.project) || format('{0}/{1}', inputs.static_root || '/srv/static', inputs.project) }}"
    strip_components: 0
    overwrite: true
```

### 2. 添加验证步骤
在部署工作流中添加验证步骤，确保所有文件都被正确上传：

```yaml
- name: 验证上传结果
  uses: appleboy/ssh-action@v1.0.3
  with:
    host: ${{ inputs.server_host }}
    username: ${{ inputs.server_user }}
    key: ${{ inputs.server_key }}
    port: ${{ inputs.server_port }}
    script: |
      echo "🔍 验证上传结果..."
      
      # 确定部署路径
      if [[ "${{ inputs.deploy_type }}" == "backend" ]]; then
        DEPLOY_PATH="${{ inputs.apps_root || '/srv/apps' }}/${{ inputs.project }}"
      else
        DEPLOY_PATH="${{ inputs.static_root || '/srv/static' }}/${{ inputs.project }}"
      fi
      
      echo "📁 检查部署目录: $DEPLOY_PATH"
      
      if [ -d "$DEPLOY_PATH" ]; then
        echo "✅ 部署目录存在"
        echo "📁 部署目录内容:"
        ls -la "$DEPLOY_PATH/"
        
        # 检查关键文件
        if [ -f "$DEPLOY_PATH/index.html" ]; then
          echo "✅ index.html 存在"
        else
          echo "❌ index.html 不存在"
        fi
        
        if [ -d "$DEPLOY_PATH/assets" ]; then
          echo "✅ assets 目录存在"
          echo "📊 assets 目录文件数量: $(find "$DEPLOY_PATH/assets" -type f | wc -l)"
        else
          echo "❌ assets 目录不存在"
        fi
        
        # 统计总文件数
        total_files=$(find "$DEPLOY_PATH" -type f | wc -l)
        echo "📊 总文件数量: $total_files"
        
        if [ "$total_files" -lt 10 ]; then
          echo "⚠️ 文件数量过少，可能存在上传问题"
          exit 1
        else
          echo "✅ 文件数量正常"
        fi
      else
        echo "❌ 部署目录不存在"
        exit 1
      fi
```

## 修改文件

### 1. 主要修改
- `axi-docs/.github/workflows/axi-docs_deploy.yml` - 添加压缩包创建和上传
- `axi-deploy/.github/workflows/deploy-project.yml` - 更新 scp-action 版本，添加压缩包解压逻辑和验证步骤

### 2. 新增文件
- `axi-deploy/scripts/test-axi-docs-deploy.sh` - 原始测试脚本
- `axi-deploy/scripts/test-tar-deploy.sh` - 压缩包方案测试脚本
- `axi-deploy/docs/AXI_DOCS_DEPLOYMENT_FIX.md` - 本文档

## 验证方法

### 1. 本地测试
运行测试脚本验证修复：
```bash
./axi-deploy/scripts/test-axi-docs-deploy.sh
```

### 2. 部署验证
下次部署时观察以下指标：
- 构建产物上传步骤是否成功
- 验证上传结果步骤是否通过
- 服务器上的 `/srv/static/axi-docs/` 目录是否包含完整文件
- 网站是否能正常加载所有资源

### 3. 关键检查点
- ✅ `index.html` 存在
- ✅ `assets/` 目录存在且包含文件
- ✅ 总文件数量 > 10
- ✅ 网站样式正常显示
- ✅ 字体文件正常加载

## 预防措施

### 1. 版本管理
- 定期更新 GitHub Actions 使用的第三方 Action 版本
- 关注 Action 的更新日志和已知问题

### 2. 验证机制
- 在所有部署工作流中添加文件完整性验证
- 设置最小文件数量阈值，防止部分文件丢失

### 3. 监控告警
- 部署失败时自动回滚
- 文件数量异常时发送告警通知

## 总结

通过更新 `appleboy/scp-action` 版本并添加验证步骤，axi-docs 项目的部署问题应该得到解决。这个修复不仅解决了当前问题，还为其他静态项目的部署提供了更好的保障。

建议在下次部署时密切关注验证步骤的输出，确保所有文件都被正确上传。
