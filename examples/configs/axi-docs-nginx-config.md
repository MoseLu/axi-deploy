# Axi-Docs Nginx 配置示例

## 部署配置

要将 axi-docs 项目部署到 `https://redamancy.com.cn/docs/` 路径下，请使用以下配置：

### 部署参数

- **项目名称**: `axi-docs`
- **部署路径**: `/www/wwwroot/redamancy.com.cn/docs`
- **源仓库**: `MoseLu/axi-docs`
- **构建运行ID**: (从构建工作流获取)

### Nginx 配置

在部署时，提供以下 Nginx 配置内容：

```nginx
# axi-docs 项目配置 - 彻底解决重定向问题
location /docs/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
    
    # 禁用任何重定向
    add_header X-Robots-Tag "noindex, nofollow";
    
    # 设置正确的Content-Type
    location ~* \.html$ {
        add_header Content-Type "text/html; charset=utf-8";
    }
}
```

### 调试步骤

在部署前，请在服务器上执行以下命令检查现有配置：

```bash
# 1. 检查所有Nginx配置文件
find /www/server/nginx/conf -name "*.conf" -exec grep -l "docs" {} \;

# 2. 检查主配置文件
cat /www/server/nginx/conf/vhost/redamancy.com.cn.conf

# 3. 检查是否有其他重定向规则
grep -r "301\|302\|redirect" /www/server/nginx/conf/

# 4. 检查Nginx错误日志
tail -f /var/log/nginx/error.log

# 5. 测试配置语法
nginx -t
```

### 备用配置（如果上述不工作）

```nginx
# axi-docs 项目配置 - 备用版本
location /docs {
    alias /www/wwwroot/redamancy.com.cn/docs;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
}
```

### Nginx 配置文件路径

- **Nginx配置路径**: `/www/server/nginx/conf/vhost/redamancy.com.cn.conf`

### 测试URL

- **测试URL**: `https://redamancy.com.cn/docs/`
- **验证**: 应该直接返回200状态码，无重定向

## 使用说明

1. **首先执行调试步骤**，检查服务器上的现有配置
2. 在 GitHub Actions 中手动触发 "Deploy Center" 工作流
3. 填写上述参数
4. 在 `nginx_config` 字段中粘贴 Nginx 配置内容（推荐使用第一个彻底解决版本）
5. 在 `nginx_path` 字段中填写配置文件路径
6. 在 `test_url` 字段中填写测试URL
7. 点击运行

## 注意事项

1. 确保服务器上的 Nginx 配置目录存在且有写入权限
2. 确保部署路径 `/www/wwwroot/redamancy.com.cn/docs` 存在
3. **重要**: 执行调试步骤，检查是否有其他配置文件在起作用
4. **重要**: 如果使用include方式，确保主配置文件中包含了项目配置文件
5. **调试**: 如果仍有问题，检查Nginx错误日志 `/var/log/nginx/error.log`
6. **性能**: 如果SCP传输慢，检查网络连接和文件大小
7. **缓存**: 清除浏览器缓存和CDN缓存（如果有） 