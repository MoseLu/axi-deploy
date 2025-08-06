# 部署工作流301重定向问题修复指南

## 🚨 问题描述

部署后仍然出现301重定向问题，即使删除了所有route文件重新部署还是301：

```
out: HTTP测试结果: 301
out: HTTPS测试结果: 301
out: 重定向目标: https://redamancy.com.cn/
out: ❌ HTTPS网站无法访问 (HTTP 301) - 部署失败
```

## 🔍 问题根本原因

问题出在`universal_deploy.yml`的nginx配置生成逻辑中：

1. **冲突检测过于严格**: 当检测到多个配置文件都有`location /`时，系统会跳过当前配置
2. **保持现有配置**: 冲突检测逻辑会保持现有配置不变，导致修复无效
3. **循环冲突**: 即使删除了route文件，重新部署时仍然会检测到冲突并跳过

## 🛠️ 修复方案

### 方案1：修改部署工作流（推荐）

我已经修改了`universal_deploy.yml`中的冲突检测逻辑：

1. **改进冲突检测**: 更精确地检测location冲突
2. **强制覆盖**: 当检测到冲突时，强制覆盖而不是跳过
3. **清理冲突文件**: 自动删除冲突的配置文件

### 方案2：修改项目配置

修改了`axi-star-cloud_deploy.yml`中的nginx配置：

```nginx
# 原来的配置（会导致冲突）
location / { ... }

# 修改后的配置（避免冲突）
location ~ ^/(?!docs|static|api|health|uploads|$) { ... }
```

### 方案3：立即修复服务器配置

在服务器上运行立即修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/immediate-fix-301.sh
chmod +x immediate-fix-301.sh
sudo ./immediate-fix-301.sh
```

## 🔧 修复原理

### 问题分析

1. **部署工作流问题**: `universal_deploy.yml`中的冲突检测逻辑过于保守
2. **配置冲突**: 多个项目都配置了`location /`，导致nginx配置冲突
3. **跳过机制**: 冲突检测会跳过当前配置，保持现有配置不变

### 修复关键点

1. **改进冲突检测**: 更精确地检测location冲突
2. **强制覆盖**: 当检测到冲突时，强制覆盖而不是跳过
3. **自动清理**: 自动删除冲突的配置文件
4. **避免冲突**: 使用更精确的location匹配规则

### 新的冲突检测逻辑

```bash
# 检查当前配置中是否包含location /
CURRENT_HAS_LOCATION_ROOT=false
if echo "$CLEANED_CONFIG" | grep -q "location /"; then
    CURRENT_HAS_LOCATION_ROOT=true
fi

# 检查其他route文件中是否包含location /
OTHER_HAS_LOCATION_ROOT=false
for other_conf in /www/server/nginx/conf/conf.d/redamancy/route-*.conf; do
    if [ -f "$other_conf" ] && [ "$other_conf" != "$ROUTE_CONF" ] && grep -q "location /" "$other_conf"; then
        OTHER_HAS_LOCATION_ROOT=true
        break
    fi
done

# 如果检测到冲突，强制覆盖
if [ "$CURRENT_HAS_LOCATION_ROOT" = true ] && [ "$OTHER_HAS_LOCATION_ROOT" = true ]; then
    echo "强制覆盖当前配置"
    # 清理冲突的配置文件
    for other_conf in /www/server/nginx/conf/conf.d/redamancy/route-*.conf; do
        if [ -f "$other_conf" ] && [ "$other_conf" != "$ROUTE_CONF" ] && grep -q "location /" "$other_conf"; then
            sudo rm -f "$other_conf"
        fi
    done
    # 写入新配置
    echo "$CLEANED_CONFIG" | sudo tee $ROUTE_CONF
fi
```

## 📋 验证修复

### 1. 重新部署项目

推送代码到GitHub触发自动部署：

```bash
git add .
git commit -m "修复301重定向问题"
git push origin main
```

### 2. 检查部署日志

在GitHub Actions中查看部署日志，确认：

- ✅ 没有检测到location冲突
- ✅ 配置文件正确写入
- ✅ nginx配置语法检查通过

### 3. 测试网站访问

```bash
# 测试主站点
curl -I https://redamancy.com.cn/

# 测试静态文件
curl -I https://redamancy.com.cn/static/html/main-content.html

# 测试API
curl -I https://redamancy.com.cn/api/health
```

## 🎯 预期结果

修复成功后应该看到：

1. **部署日志正常** - 没有冲突检测警告
2. **配置文件正确生成** - route-axi-star-cloud.conf包含正确的配置
3. **nginx配置语法正确** - 配置检查通过
4. **主页面访问正常** - 状态码200
5. **静态文件访问正常** - 状态码200或404
6. **无重定向循环** - 重定向次数≤1

## 📞 故障排除

如果问题仍然存在：

1. **检查部署日志**:
   - 查看GitHub Actions中的部署日志
   - 确认冲突检测逻辑是否正常工作

2. **检查服务器配置**:
   ```bash
   sudo cat /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf
   ```

3. **手动修复**:
   ```bash
   sudo ./immediate-fix-301.sh
   ```

4. **检查nginx错误日志**:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

## 📝 注意事项

1. **推送代码**: 修改后的配置需要推送到GitHub才能生效
2. **等待部署**: 部署过程需要几分钟时间
3. **监控日志**: 部署后监控错误日志确保无异常
4. **保持架构**: 修复后仍然保持动态引入架构
