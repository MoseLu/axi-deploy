# 🔐 Token 管理解决方案

## 📋 问题描述

Personal Access Token 只会在生成时显示一次，如果丢失就需要重新生成。对于多个项目使用部署系统，这会造成管理困难。

## ✅ 解决方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **GitHub App** | 永久有效、权限精细、安全可靠 | 配置复杂 | ⭐⭐⭐⭐⭐ |
| **组织级 Token** | 简单易用、统一管理 | 权限较粗 | ⭐⭐⭐⭐ |
| **Fine-grained Token** | 权限精细、易于管理 | 需要手动配置 | ⭐⭐⭐ |
| **Token 备份策略** | 简单直接 | 需要安全存储 | ⭐⭐ |

## 🎯 推荐方案

### 方案一：GitHub App（最佳）

**适用场景：** 企业级部署、多项目管理

**优势：**
- 永久有效，无需重新生成
- 权限精细控制
- 一个 App 服务多个仓库
- 安全可靠

**配置步骤：**
1. 创建 GitHub App
2. 配置必要权限
3. 安装到目标组织
4. 更新部署系统使用 App Token

### 方案二：组织级 Personal Access Token（推荐）

**适用场景：** 中小型团队、快速部署

**优势：**
- 配置简单
- 统一管理
- 易于维护

**配置步骤：**

#### 1. 创建组织级 Token

1. 访问 GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 点击 "Generate new token (classic)"
3. 配置权限：
   - ✅ `repo` - 完整的仓库访问权限
   - ✅ `workflow` - 工作流权限
4. 设置过期时间：建议选择 "No expiration" 或较长时间
5. 复制并安全保存 Token

#### 2. 安全存储 Token

**方法一：使用密码管理器**
```bash
# 推荐使用 1Password、Bitwarden 等密码管理器
# 存储格式：
# 名称：AXI Deploy Center Token
# 值：ghp_xxxxxxxxxxxxxxxxxxxx
# 备注：用于 AXI 多语言部署系统
```

**方法二：使用环境变量文件**
```bash
# 创建 .env 文件（不要提交到 Git）
echo "DEPLOY_CENTER_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx" > .env
```

**方法三：使用 GitHub Gist**
1. 创建私有 Gist
2. 存储 Token 信息
3. 需要时从 Gist 获取

#### 3. 配置到所有项目

在每个业务仓库中配置相同的 Secret：

| Secret 名称 | 值 |
|-------------|-----|
| `DEPLOY_CENTER_PAT` | `ghp_xxxxxxxxxxxxxxxxxxxx` |

### 方案三：Fine-grained Personal Access Token

**适用场景：** 需要精确权限控制

**配置步骤：**

1. 访问 GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. 点击 "Generate new token"
3. 配置权限：
   - **Repository access**: 选择 "Only select repositories"
   - **Permissions**:
     - `Repository permissions` → `Contents` → `Read`
     - `Repository permissions` → `Actions` → `Read`
     - `Repository permissions` → `Workflows` → `Read`
4. 选择需要授权的仓库
5. 设置过期时间
6. 复制并保存 Token

## 🔄 迁移指南

### 从个人 Token 迁移到组织 Token

#### 步骤 1：创建组织级 Token
```bash
# 1. 生成新的组织级 Token
# 2. 安全保存 Token
# 3. 记录 Token 信息
```

#### 步骤 2：更新所有项目
```bash
# 在每个业务仓库中更新 Secret
# 名称：DEPLOY_CENTER_PAT
# 值：新的组织级 Token
```

#### 步骤 3：测试部署
```bash
# 1. 运行测试连接工作流
# 2. 触发一次部署测试
# 3. 验证部署成功
```

#### 步骤 4：清理旧 Token
```bash
# 1. 删除旧的个人 Token
# 2. 更新相关文档
# 3. 通知团队成员
```

## 🛡️ 安全最佳实践

### 1. Token 存储安全

**✅ 推荐做法：**
- 使用密码管理器存储
- 设置强密码保护
- 定期备份 Token 信息
- 限制访问权限

**❌ 避免做法：**
- 明文存储在代码中
- 提交到 Git 仓库
- 分享给不相关人员
- 使用弱密码保护

### 2. 权限最小化

**✅ 推荐做法：**
- 只授予必要权限
- 定期审查权限
- 使用 Fine-grained Token
- 设置合理的过期时间

**❌ 避免做法：**
- 授予过多权限
- 使用永不过期的 Token
- 忽略权限审查

### 3. 监控和审计

**✅ 推荐做法：**
- 定期检查 Token 使用情况
- 监控异常访问
- 记录 Token 变更
- 设置访问通知

## 📋 应急处理

### Token 丢失或泄露

#### 立即处理：
1. **立即撤销 Token**
   - 访问 GitHub Settings → Developer settings → Personal access tokens
   - 找到对应 Token 并点击 "Delete"

2. **生成新 Token**
   - 按照上述步骤生成新 Token
   - 更新所有相关仓库的 Secrets

3. **通知团队**
   - 通知所有使用该 Token 的团队成员
   - 更新相关文档

#### 预防措施：
1. **定期轮换 Token**
   - 建议每 6-12 个月轮换一次
   - 设置提醒机制

2. **监控使用情况**
   - 定期检查 Token 使用日志
   - 设置异常访问告警

## 📚 相关资源

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Fine-grained Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-fine-grained-personal-access-token)
- [GitHub Apps](https://docs.github.com/en/developers/apps)

## 🎯 推荐方案总结

### 小型团队（1-5人）
**推荐：组织级 Personal Access Token**
- 配置简单
- 易于管理
- 成本低

### 中型团队（5-20人）
**推荐：Fine-grained Personal Access Token**
- 权限精细
- 安全性好
- 易于审计

### 大型团队（20人以上）
**推荐：GitHub App**
- 企业级安全
- 统一管理
- 可扩展性强

---

🔐 **选择适合您团队的方案，确保 Token 安全的同时，享受便捷的部署体验！** 