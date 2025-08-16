# 动态端口分配系统

## 概述

动态端口分配系统是 axi-deploy 项目的一个新功能，用于在服务器上自动检查和分配可用端口，避免端口冲突问题。

## 功能特性

### 🎯 核心功能
- **自动端口检测**: 实时检查端口占用情况
- **智能端口分配**: 在指定范围内自动分配可用端口
- **端口冲突避免**: 确保每个项目使用唯一端口
- **配置持久化**: 将端口分配信息保存到服务器配置文件

### 🔧 管理功能
- **端口状态监控**: 查看所有端口的使用情况
- **手动端口管理**: 支持手动分配和释放端口
- **配置清理**: 自动清理无效的端口分配
- **防火墙检查**: 验证端口是否在防火墙中开放

## 系统架构

### 工作流集成
```
main-deployment.yml
├── dynamic-port-allocation.yml (新增)
├── deploy-project.yml
├── configure-nginx.yml
├── start-service.yml
└── test-website.yml
```

### 端口分配流程
1. **验证阶段**: 检查输入参数和服务器连接
2. **端口检测**: 扫描端口范围，检查占用情况
3. **端口分配**: 选择最小可用端口进行分配
4. **配置更新**: 更新服务器上的端口配置文件
5. **服务启动**: 使用分配的端口启动服务

## 配置文件

### 服务器端口配置
位置: `/srv/port-config.yml`

```yaml
# 动态端口配置
# 自动生成和维护
# 最后更新: 2024-01-15 10:30:00

projects:
  axi-star-cloud:
    port: 8080
    description: "自动分配 - 2024-01-15 10:30:00"
    allocated_at: "2024-01-15T10:30:00+08:00"
    
  axi-project-dashboard:
    port: 8090
    description: "自动分配 - 2024-01-15 10:35:00"
    allocated_at: "2024-01-15T10:35:00+08:00"
```

## 使用方法

### 1. 自动部署（推荐）

在部署后端项目时，系统会自动进行端口分配：

```yaml
# 在 main-deployment.yml 中自动调用
dynamic-port-allocation:
  needs: [parse-secrets, validate-artifact, parse-deploy-config]
  if: ${{ inputs.deploy_type == 'backend' }}
  uses: ./.github/workflows/dynamic-port-allocation.yml
  with:
    project: ${{ inputs.project }}
    server_host: ${{ needs.parse-secrets.outputs.server_host }}
    # ... 其他参数
```

### 2. 手动管理

使用端口管理脚本进行手动操作：

```bash
# 在服务器上执行
sudo ./scripts/manage-ports.sh

# 常用命令
./scripts/manage-ports.sh list          # 列出所有端口
./scripts/manage-ports.sh allocate my-project  # 分配端口
./scripts/manage-ports.sh release my-project   # 释放端口
./scripts/manage-ports.sh check 8080    # 检查端口
./scripts/manage-ports.sh status        # 显示状态
```

## 端口管理脚本

### 安装
```bash
# 将脚本复制到服务器
scp axi-deploy/scripts/manage-ports.sh user@server:/tmp/
ssh user@server "sudo mv /tmp/manage-ports.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/manage-ports.sh"
```

### 命令说明

| 命令 | 参数 | 说明 |
|------|------|------|
| `list` | 无 | 列出所有已分配的端口 |
| `check` | `<port>` | 检查指定端口是否可用 |
| `allocate` | `<project>` | 为项目分配端口 |
| `release` | `<project>` | 释放项目端口 |
| `find` | `<project>` | 查找项目当前端口 |
| `status` | 无 | 显示端口使用状态 |
| `cleanup` | 无 | 清理无效的端口分配 |
| `help` | 无 | 显示帮助信息 |

### 使用示例

```bash
# 查看当前端口分配
manage-ports.sh list

# 为新项目分配端口
manage-ports.sh allocate my-new-project

# 检查特定端口
manage-ports.sh check 8080

# 释放项目端口
manage-ports.sh release old-project

# 查看端口状态
manage-ports.sh status
```

## 端口分配策略

### 分配优先级
1. **首选端口**: 如果指定了首选端口且可用，优先使用
2. **最小可用端口**: 在端口范围内选择最小的可用端口
3. **默认端口**: 如果都不可用，使用默认端口 8080

### 端口范围
- **起始端口**: 8080
- **结束端口**: 10000
- **可用端口数**: 9,921 个

### 冲突处理
- 自动检测端口占用
- 跳过已被占用的端口
- 记录分配历史，避免重复分配

## 集成说明

### 与现有系统的兼容性

1. **向后兼容**: 保持与现有静态端口配置的兼容性
2. **优先级机制**: 动态分配端口 > 静态配置端口 > 默认端口
3. **配置迁移**: 支持从静态配置迁移到动态配置

### 工作流修改

#### main-deployment.yml
```yaml
# 新增动态端口分配步骤
dynamic-port-allocation:
  needs: [parse-secrets, validate-artifact, parse-deploy-config]
  if: ${{ inputs.deploy_type == 'backend' }}
  uses: ./.github/workflows/dynamic-port-allocation.yml
  with:
    project: ${{ inputs.project }}
    # ... 其他参数

# 修改后续步骤依赖
deploy-project:
  needs: [parse-secrets, validate-artifact, parse-deploy-config, dynamic-port-allocation]
  # ...

start-service:
  needs: [parse-secrets, deploy-project, configure-nginx, parse-deploy-config, dynamic-port-allocation]
  # ...
```

#### start-service.yml
```yaml
# 修改端口获取逻辑
service_port: ${{ needs.dynamic-port-allocation.outputs.allocated_port || needs.parse-deploy-config.outputs.service_port || '' }}
```

## 监控和维护

### 日志记录
- 端口分配操作记录在 GitHub Actions 日志中
- 服务器端操作记录在系统日志中
- 配置文件变更记录在 `/srv/port-config.yml` 中

### 定期维护
```bash
# 清理无效端口分配
manage-ports.sh cleanup

# 检查端口状态
manage-ports.sh status

# 备份端口配置
sudo cp /srv/port-config.yml /srv/port-config.yml.backup
```

### 故障排除

#### 常见问题

1. **端口分配失败**
   ```bash
   # 检查端口范围
   manage-ports.sh status
   
   # 清理无效分配
   manage-ports.sh cleanup
   ```

2. **配置文件损坏**
   ```bash
   # 恢复备份
   sudo cp /srv/port-config.yml.backup /srv/port-config.yml
   
   # 重新初始化
   sudo rm /srv/port-config.yml
   manage-ports.sh allocate project-name
   ```

3. **防火墙问题**
   ```bash
   # 检查防火墙状态
   sudo firewall-cmd --list-ports
   
   # 开放端口范围
   sudo firewall-cmd --permanent --add-port=8080-10000/tcp
   sudo firewall-cmd --reload
   ```

## 最佳实践

### 1. 端口管理
- 定期清理无效的端口分配
- 监控端口使用情况
- 备份端口配置文件

### 2. 部署策略
- 优先使用动态端口分配
- 为重要项目保留特定端口
- 记录端口分配历史

### 3. 安全考虑
- 定期检查端口安全性
- 限制端口访问权限
- 监控异常端口使用

## 更新日志

### v1.0.0 (2024-01-15)
- ✅ 实现动态端口分配功能
- ✅ 集成到主部署工作流
- ✅ 添加端口管理脚本
- ✅ 支持端口冲突检测
- ✅ 实现配置持久化

### 计划功能
- 🔄 端口使用统计和分析
- 🔄 端口分配策略优化
- 🔄 多服务器端口同步
- 🔄 端口健康检查

## 技术支持

如有问题，请参考：
1. [GitHub Actions 日志](https://github.com/MoseLu/axi-deploy/actions)
2. [服务器端口管理脚本](./scripts/manage-ports.sh)
3. [工作流配置文件](./.github/workflows/)

## 📊 工作流统计

### 新增工作流
- **dynamic-port-allocation.yml**: 动态端口分配工作流
  - 大小: 约 8KB
  - 功能: 自动端口检测和分配
  - 集成: 主部署流程

### 更新工作流
- **main-deployment.yml**: 集成动态端口分配
- **start-service.yml**: 支持动态端口配置

### 新增工具
- **manage-ports.sh**: 端口管理脚本
  - 大小: 约 15KB
  - 功能: 手动端口管理
  - 位置: `scripts/manage-ports.sh`

### 总工作流数量
- **更新前**: 17个工作流
- **更新后**: 18个工作流 (+1)
- **新增功能**: 动态端口分配系统

---

*最后更新: 2024-01-15*
