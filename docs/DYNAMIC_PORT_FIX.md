# 动态端口分配修复方案

## 问题描述

在部署过程中，动态端口分配与项目配置之间存在冲突，导致服务启动失败。具体表现为：

1. 端口配置文件中 `axi-star-cloud` 的端口是 8080
2. 动态端口分配脚本分配了 8124
3. 应用启动时使用了 8124，但服务验证失败

## 解决方案

### 1. 修改端口配置文件

将 `axi-star-cloud` 的端口从 8080 改为 8124，与动态分配的端口保持一致：

```yaml
# axi-deploy/port-config.yml
projects:
  axi-star-cloud:
    port: 8124  # 从 8080 改为 8124
    description: "星云核心服务"
```

### 2. 优化动态端口分配逻辑

修改 `dynamic-port-allocation.yml` 工作流，让端口分配优先使用配置文件中的端口：

#### 2.1 修改 `find_available_port` 函数

```bash
find_available_port() {
  local start_port=$1
  local end_port=$2
  local preferred_port=$3
  local project_name=$4  # 新增项目名称参数
  
  # 方法1: 优先检查配置文件中的端口
  if [ -n "$project_name" ] && [ -f "/srv/port-config.yml" ]; then
    local config_port=$(grep -A 1 "^  $project_name:" /srv/port-config.yml | grep "port:" | awk '{print $2}')
    if [ -n "$config_port" ] && [ "$config_port" -ge "$start_port" ] && [ "$config_port" -le "$end_port" ]; then
      if check_port_available "$config_port"; then
        echo "$config_port"
        return 0
      fi
    fi
  fi
  
  # 方法2: 检查首选端口
  # 方法3: 从起始端口开始查找
}
```

#### 2.2 添加 Nginx 配置更新功能

```bash
update_nginx_config() {
  local project=$1
  local port=$2
  
  local nginx_conf_dir="/www/server/nginx/conf/conf.d/redamancy"
  local nginx_config_file="$nginx_conf_dir/$project.conf"
  
  if [ -f "$nginx_config_file" ]; then
    # 备份原配置文件
    sudo cp "$nginx_config_file" "$nginx_config_file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 更新端口
    sudo sed -i "s/listen [0-9]*;/listen $port;/g" "$nginx_config_file"
    sudo sed -i "s/proxy_pass http:\/\/[^:]*:[0-9]*/proxy_pass http:\/\/127.0.0.1:$port/g" "$nginx_config_file"
    
    # 测试并重新加载配置
    if sudo nginx -t 2>/dev/null; then
      sudo systemctl reload nginx
    fi
  fi
}
```

### 3. 优化服务启动逻辑

修改 `start-service.yml` 工作流，优先使用配置文件中的端口：

```bash
# 方法1: 优先从服务器动态端口配置文件获取端口（最高优先级）
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /tmp/ssh_key -p ${{ inputs.server_port }} ${{ inputs.server_user }}@${{ inputs.server_host }} '[ -f "/srv/port-config.yml" ]' 2>/dev/null; then
  SERVICE_PORT=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /tmp/ssh_key -p ${{ inputs.server_port }} ${{ inputs.server_user }}@${{ inputs.server_host }} "grep -A 1 '^  $PROJECT_NAME:' /srv/port-config.yml | grep 'port:' | awk '{print \$2}'" 2>/dev/null)
  if [ -n "$SERVICE_PORT" ]; then
    echo "✅ 从服务器动态端口配置获取端口: $SERVICE_PORT"
  fi
fi

# 方法2: 如果服务器配置中没有找到，从输入参数获取端口
if [ -z "$SERVICE_PORT" ] && [ ! -z "${{ inputs.service_port }}" ]; then
  SERVICE_PORT="${{ inputs.service_port }}"
  echo "✅ 从输入参数获取端口: $SERVICE_PORT"
fi
```

### 4. 创建端口配置同步脚本

创建 `sync-port-config.sh` 脚本来同步本地配置到服务器：

```bash
# 用法: ./sync-port-config.sh <server_host> <server_user> <server_port>
./axi-deploy/scripts/sync-port-config.sh 47.112.163.152 deploy 22
```

## 使用步骤

### 1. 同步端口配置

```bash
# 在 axi-deploy 目录下执行
./scripts/sync-port-config.sh 47.112.163.152 deploy 22
```

### 2. 重新部署项目

触发 GitHub Actions 工作流重新部署 `axi-star-cloud` 项目。

### 3. 验证部署结果

检查服务是否在正确的端口（8124）上启动：

```bash
# 检查端口监听
netstat -tlnp | grep 8124

# 检查服务状态
curl http://localhost:8124/health
```

## 配置优先级

1. **服务器端口配置文件** (`/srv/port-config.yml`) - 最高优先级
2. **输入参数** (`service_port`) - 中等优先级
3. **本地配置文件** (`port-config.yml`) - 低优先级
4. **默认端口** (8080) - 最低优先级

## 自动化流程

1. 动态端口分配时，优先使用配置文件中的端口
2. 如果配置文件中的端口不可用，分配新端口并更新配置
3. 自动更新应用程序配置文件（Go/Node.js）
4. 自动更新 Nginx 配置文件
5. 重新加载 Nginx 配置

## 故障排除

### 端口冲突

如果遇到端口冲突，可以：

1. 检查端口占用：`netstat -tlnp | grep <port>`
2. 强制重新分配：设置 `force_reallocate=true`
3. 手动修改端口配置文件

### 配置不同步

如果本地和服务器配置不同步：

1. 运行同步脚本：`./sync-port-config.sh`
2. 检查服务器配置：`cat /srv/port-config.yml`
3. 重新部署项目

### 服务启动失败

如果服务启动失败：

1. 检查端口配置：`grep -A 1 "axi-star-cloud" /srv/port-config.yml`
2. 检查应用配置：`cat /srv/apps/axi-star-cloud/backend/config/config.yaml`
3. 检查服务日志：`journalctl -u star-cloud.service -f`
