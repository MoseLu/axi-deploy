# Axi-Star-Cloud 部署问题修复总结

## 问题分析

### 原始问题
- axi-star-cloud项目在修改axi-docs后出现403错误
- 部署流程不统一，没有使用axi-deploy的统一部署中心
- 缺乏多项目部署的Nginx配置管理

### 根本原因
1. **部署流程不一致** - axi-star-cloud使用直接SSH部署，而axi-docs使用axi-deploy统一部署
2. **Nginx配置冲突** - 多项目部署时Nginx配置可能相互覆盖
3. **缺乏模块化管理** - 没有使用Nginx include功能来管理多项目配置

## 解决方案

### 1. 统一部署流程

将axi-star-cloud的部署工作流改为使用axi-deploy的统一部署中心：

**修改前**：
```yaml
# 直接SSH部署方式
- name: 部署并重启后端
  run: |
    scp -o StrictHostKeyChecking=no deploy.sh ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }}:/tmp/
    ssh -o StrictHostKeyChecking=no ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }} "chmod +x /tmp/deploy.sh && /tmp/deploy.sh"
```

**修改后**：
```yaml
# 使用axi-deploy统一部署
deploy:
  needs: build
  uses: MoseLu/axi-deploy/.github/workflows/external-deploy.yml@master
  with:
    project: ${{ github.event.repository.name }}
    deploy_path: /www/wwwroot/${{ github.event.repository.name }}
    start_cmd: |
      # 解包部署文件
      tar xzf deployment.tar.gz -C /www/wwwroot/${{ github.event.repository.name }}/
      chmod +x /www/wwwroot/${{ github.event.repository.name }}/star-cloud-linux
      # ... 其他启动命令
```

### 2. 多项目Nginx配置管理

引入Nginx include功能来管理多项目配置：

**目录结构**：
```
/www/server/nginx/conf/vhost/
├── redamancy.com.cn.conf          # 主域名配置文件
└── includes/                      # 项目配置目录
    ├── axi-docs.conf             # axi-docs项目配置
    ├── axi-star-cloud.conf       # axi-star-cloud项目配置
    └── other-project.conf        # 其他项目配置
```

**主域名配置**：
```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name redamancy.com.cn;
    
    # 主项目配置（axi-star-cloud）
    location / {
        root /www/wwwroot/axi-star-cloud;
        try_files $uri $uri/ /index.html;
    }
    
    # API代理到Go后端
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 包含其他项目配置
    include /www/server/nginx/conf/vhost/includes/*.conf;
}
```

### 3. 改进的部署流程

#### 构建阶段
1. 检出代码
2. 设置Go环境
3. 构建Go二进制文件
4. 打包所有必要文件（二进制、前端、配置、服务文件）
5. 上传构建产物

#### 部署阶段
1. 下载构建产物
2. 上传到服务器
3. 解包部署文件
4. 设置文件权限
5. 配置systemd服务
6. 重启服务
7. 健康检查
8. 配置Nginx（包含include目录创建）

### 4. 增强的错误处理

#### 部署验证
- 服务状态检查
- 端口监听验证
- API响应测试
- Nginx配置语法检查
- 文件权限验证

#### 故障排除
- 详细的错误日志
- 自动化验证脚本
- 常见问题解决方案
- 调试命令集合

## 改进效果

### 1. 统一性
- ✅ 所有项目使用相同的部署流程
- ✅ 统一的错误处理和日志记录
- ✅ 一致的配置管理方式

### 2. 可维护性
- ✅ 模块化的Nginx配置
- ✅ 独立的项目配置管理
- ✅ 清晰的部署文档

### 3. 可扩展性
- ✅ 支持多项目部署
- ✅ 易于添加新项目
- ✅ 灵活的配置选项

### 4. 稳定性
- ✅ 增强的错误处理
- ✅ 自动化验证流程
- ✅ 详细的故障排除指南

## 部署检查清单

### 部署前检查
- [ ] 确保axi-deploy仓库配置正确
- [ ] 验证GitHub Secrets设置
- [ ] 检查服务器SSH连接
- [ ] 确认Nginx配置目录权限

### 部署后验证
- [ ] Go服务正常启动
- [ ] 端口8080正常监听
- [ ] API端点响应正常
- [ ] Nginx配置语法正确
- [ ] 静态文件访问正常
- [ ] 数据库连接正常

### 多项目验证
- [ ] axi-docs访问正常（/docs/）
- [ ] axi-star-cloud访问正常（/）
- [ ] API代理工作正常（/api/）
- [ ] 各项目配置相互独立

## 使用说明

### 1. 部署axi-star-cloud
```bash
# 推送代码到main分支触发自动部署
git push origin main

# 或手动触发部署
# 在GitHub Actions中手动运行"Build & Deploy Go Project"工作流
```

### 2. 验证部署
```bash
# 运行验证脚本
curl -v https://redamancy.com.cn/health
curl -v https://redamancy.com.cn/api/health
```

### 3. 查看日志
```bash
# 查看服务日志
sudo journalctl -u star-cloud.service -f

# 查看Nginx日志
sudo tail -f /var/log/nginx/error.log
```

## 注意事项

1. **首次部署** - 确保服务器上有正确的目录结构和权限
2. **配置备份** - 修改Nginx配置前先备份现有配置
3. **服务重启** - 部署后会自动重启服务，确保没有数据丢失
4. **监控日志** - 部署后密切关注服务日志和Nginx日志
5. **测试访问** - 部署完成后测试所有功能是否正常

## 故障排除

如果遇到问题，请按以下顺序检查：

1. **服务状态** - `sudo systemctl status star-cloud.service`
2. **端口监听** - `sudo netstat -tlnp | grep :8080`
3. **API响应** - `curl -v http://127.0.0.1:8080/health`
4. **Nginx配置** - `sudo nginx -t`
5. **文件权限** - `ls -la /www/wwwroot/axi-star-cloud/`
6. **错误日志** - `sudo journalctl -u star-cloud.service --no-pager`

## 联系支持

如果问题仍然存在，请提供：
1. 服务状态日志
2. Nginx错误日志
3. 部署工作流日志
4. 网络连接测试结果 