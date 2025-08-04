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
location /docs/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    try_files $uri $uri/ /docs/index.html;
    
    # 设置缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 设置正确的 MIME 类型
    location ~* \.(js)$ {
        add_header Content-Type application/javascript;
    }
    
    location ~* \.(css)$ {
        add_header Content-Type text/css;
    }
}
```

### Nginx 配置文件路径

- **Nginx配置路径**: `/www/server/nginx/conf/vhost/redamancy.com.cn.conf`

### 测试URL

- **测试URL**: `https://redamancy.com.cn/docs/`

## 使用说明

1. 在 GitHub Actions 中手动触发 "Deploy Center" 工作流
2. 填写上述参数
3. 在 `nginx_config` 字段中粘贴 Nginx 配置内容
4. 在 `nginx_path` 字段中填写配置文件路径
5. 在 `test_url` 字段中填写测试URL
6. 点击运行

## 注意事项

1. 确保服务器上的 Nginx 配置目录存在且有写入权限
2. 确保部署路径 `/www/wwwroot/redamancy.com.cn/docs` 存在
3. 如果主域名配置文件中已有 `/docs/` 路径配置，请先备份或删除
4. 部署完成后，访问 `https://redamancy.com.cn/docs/` 验证是否正常 