# MySQL 数据库备份功能使用指南

## 概述

axi-deploy 现在支持为使用 MySQL 数据库的后端项目自动配置数据库备份机制。该功能会在部署过程中自动检测项目是否使用 MySQL 数据库，如果检测到，会自动设置备份机制。

## 功能特性

### 🔍 自动检测
- 自动检测项目是否使用 MySQL 数据库
- 支持多种配置文件格式（YAML、JSON、环境变量）
- 支持 Node.js 和 Go 项目
- 自动提取数据库名称

### 📋 备份方式
- **mysqldump**: 逻辑备份，适合中小型数据库
- **xtrabackup**: 物理备份，适合大型数据库（需要额外安装）

### ⏰ 定时备份
- 自动设置定时备份任务（默认每天凌晨 2 点）
- 可配置备份保留天数（默认 30 天）
- 自动清理过期备份文件

### 🔧 灵活配置
- 支持自定义 MySQL 连接参数
- 支持自定义备份方法和保留策略
- 支持多种数据库名称检测方式

## 使用方法

### 1. 基本使用（自动检测）

对于大多数项目，只需要在部署配置中添加 MySQL 连接参数即可：

```yaml
# 在业务仓库的部署工作流中
- name: 触发部署
  uses: actions/github-script@v7
  with:
    script: |
      await github.rest.actions.createWorkflowDispatch({
        owner: 'MoseLu',
        repo: 'axi-deploy',
        workflow_id: 'main-deployment.yml',
        ref: 'master',
        inputs: {
          project: context.repo.repo,
          source_repo: `${context.repo.owner}/${context.repo.repo}`,
          run_id: process.env.RUN_ID,
          deploy_type: 'backend',
          # MySQL 备份相关参数
          mysql_host: 'localhost',
          mysql_port: '3306',
          mysql_user: 'root',
          mysql_password: '${{ secrets.MYSQL_PASSWORD }}',
          # 可选：指定数据库名称（如果不指定会自动检测）
          database_name: 'my_project_db',
          # 可选：指定备份方法
          backup_method: 'mysqldump',
          # 可选：指定备份保留天数
          backup_retention_days: '30'
        }
      });
```

### 2. 高级配置

#### 使用 xtrabackup 备份

```yaml
inputs: {
  # ... 其他参数
  backup_method: 'xtrabackup',
  mysql_host: 'mysql.example.com',
  mysql_port: '3306',
  mysql_user: 'backup_user',
  mysql_password: '${{ secrets.MYSQL_BACKUP_PASSWORD }}'
}
```

#### 自定义备份保留策略

```yaml
inputs: {
  # ... 其他参数
  backup_retention_days: '7',  # 只保留 7 天的备份
  backup_method: 'mysqldump'
}
```

## 检测机制

### 配置文件检测

系统会自动检查以下配置文件：

```
项目根目录/
├── config/
│   ├── database.yml
│   ├── database.yaml
│   ├── config.yml
│   └── config.yaml
├── .env
├── .env.production
└── backend/
    ├── config/
    │   ├── database.yml
    │   └── config.yml
    ├── .env
    └── .env.production
```

### 依赖检测

- **Node.js 项目**: 检查 `package.json` 中的 MySQL 相关依赖
- **Go 项目**: 检查 `go.mod` 中的 MySQL 相关依赖

### 数据库名称检测

1. 优先使用配置参数中指定的 `database_name`
2. 从配置文件中自动提取数据库名称
3. 使用项目名称 + "_db" 作为默认数据库名称

## 备份文件结构

```
/srv/backups/databases/
└── 项目名称/
    ├── 数据库名称_20241201_143022.sql.gz    # mysqldump 备份
    ├── 数据库名称_20241201_143022.tar.gz    # xtrabackup 备份
    ├── backup.sh                           # 自动备份脚本
    └── backup.log                          # 备份日志
```

## 定时备份

系统会自动设置定时备份任务：

```bash
# 每天凌晨 2 点执行备份
0 2 * * * /srv/backups/databases/项目名称/backup.sh
```

## 安全考虑

### 1. 密码安全
- MySQL 密码通过 GitHub Secrets 传递
- 备份脚本中的密码会被安全处理
- 建议使用专门的备份用户，而不是 root 用户

### 2. 文件权限
- 备份目录权限设置为 755
- 备份文件权限设置为 644
- 只有部署用户可以访问备份文件

### 3. 网络安全
- 建议使用本地 MySQL 实例
- 如果使用远程 MySQL，确保网络连接安全

## 故障排除

### 1. 备份失败

**问题**: mysqldump 备份失败
**解决方案**:
```bash
# 检查 MySQL 连接
mysql -h localhost -u root -p -e "SHOW DATABASES;"

# 检查用户权限
mysql -u root -p -e "SHOW GRANTS FOR 'backup_user'@'localhost';"
```

### 2. 定时任务不执行

**问题**: 定时备份没有执行
**解决方案**:
```bash
# 检查 crontab
crontab -l

# 手动执行备份脚本
/srv/backups/databases/项目名称/backup.sh

# 检查日志
tail -f /srv/backups/databases/项目名称/backup.log
```

### 3. 磁盘空间不足

**问题**: 备份文件占用过多磁盘空间
**解决方案**:
```bash
# 检查磁盘使用情况
df -h /srv/backups

# 手动清理旧备份
find /srv/backups/databases/项目名称/ -name "*.sql.gz" -mtime +7 -delete
```

## 最佳实践

### 1. 备份策略
- 生产环境建议使用 xtrabackup
- 开发环境可以使用 mysqldump
- 根据数据重要性调整保留天数

### 2. 监控
- 定期检查备份日志
- 监控备份文件大小
- 测试备份文件恢复

### 3. 恢复测试
```bash
# 测试恢复 mysqldump 备份
gunzip -c /srv/backups/databases/项目名称/数据库名称_20241201_143022.sql.gz | mysql -u root -p

# 测试恢复 xtrabackup 备份
# 需要先安装 xtrabackup 工具
```

## 配置示例

### Node.js + MySQL 项目

```yaml
# .github/workflows/deploy.yml
- name: 部署项目
  uses: actions/github-script@v7
  with:
    script: |
      await github.rest.actions.createWorkflowDispatch({
        owner: 'MoseLu',
        repo: 'axi-deploy',
        workflow_id: 'main-deployment.yml',
        ref: 'master',
        inputs: {
          project: context.repo.repo,
          source_repo: `${context.repo.owner}/${context.repo.repo}`,
          run_id: process.env.RUN_ID,
          deploy_type: 'backend',
          mysql_host: 'localhost',
          mysql_port: '3306',
          mysql_user: 'app_user',
          mysql_password: '${{ secrets.MYSQL_PASSWORD }}',
          database_name: 'myapp_production',
          backup_method: 'mysqldump',
          backup_retention_days: '30'
        }
      });
```

### Go + MySQL 项目

```yaml
# .github/workflows/deploy.yml
- name: 部署项目
  uses: actions/github-script@v7
  with:
    script: |
      await github.rest.actions.createWorkflowDispatch({
        owner: 'MoseLu',
        repo: 'axi-deploy',
        workflow_id: 'main-deployment.yml',
        ref: 'master',
        inputs: {
          project: context.repo.repo,
          source_repo: `${context.repo.owner}/${context.repo.repo}`,
          run_id: process.env.RUN_ID,
          deploy_type: 'backend',
          mysql_host: 'mysql.example.com',
          mysql_port: '3306',
          mysql_user: 'gouser',
          mysql_password: '${{ secrets.MYSQL_PASSWORD }}',
          backup_method: 'xtrabackup',
          backup_retention_days: '7'
        }
      });
```

## 注意事项

1. **首次部署**: 首次部署时会自动检测并设置备份机制
2. **重复部署**: 重复部署不会重复设置定时任务
3. **配置变更**: 修改备份配置需要手动更新定时任务
4. **权限要求**: 确保 MySQL 用户有足够的备份权限
5. **磁盘空间**: 定期检查备份目录的磁盘使用情况

## 支持的项目类型

- ✅ Node.js + MySQL
- ✅ Go + MySQL
- ✅ Python + MySQL
- ✅ PHP + MySQL
- ✅ Java + MySQL
- ✅ 其他使用 MySQL 的后端项目

## 联系支持

如果在使用过程中遇到问题，请：

1. 检查部署日志中的错误信息
2. 查看备份脚本的执行日志
3. 确认 MySQL 连接参数正确
4. 验证用户权限设置
