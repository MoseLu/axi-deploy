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
# axi-docs 项目配置 - 无重定向版本
location /docs/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
}
```

### 替代配置（如果上述不工作）

```nginx
# axi-docs 项目配置 - 备用无重定向版本
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

1. 在 GitHub Actions 中手动触发 "Deploy Center" 工作流
2. 填写上述参数
3. 在 `nginx_config` 字段中粘贴 Nginx 配置内容（推荐使用第一个无重定向版本）
4. 在 `nginx_path` 字段中填写配置文件路径
5. 在 `test_url` 字段中填写测试URL
6. 点击运行

## 注意事项

1. 确保服务器上的 Nginx 配置目录存在且有写入权限
2. 确保部署路径 `/www/wwwroot/redamancy.com.cn/docs` 存在
3. 如果主域名配置文件中已有 `/docs/` 路径配置，请先备份或删除
4. 部署完成后，访问 `https://redamancy.com.cn/docs/` 验证是否正常
5. **重要**: 如果使用include方式，确保主配置文件中包含了项目配置文件
6. **调试**: 如果仍有问题，检查Nginx错误日志 `/var/log/nginx/error.log`
7. **性能**: 如果SCP传输慢，检查网络连接和文件大小 