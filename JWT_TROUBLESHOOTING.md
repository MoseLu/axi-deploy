# 🔧 JWT Token 生成故障排除指南

## 🚨 常见错误

### 错误 1: "A JSON web token could not be decoded"

**原因分析：**
- 私钥格式不正确
- JWT 生成过程中出现编码问题
- Secrets 配置有误

**解决方案：**

#### 1. 检查 GitHub Secrets 配置

确保在仓库的 Settings > Secrets and variables > Actions 中正确配置了以下 Secrets：

| Secret 名称 | 描述 | 格式要求 |
|-------------|------|----------|
| `APP_ID` | GitHub App ID | 纯数字，如：`123456` |
| `APP_PRIVATE_KEY` | GitHub App 私钥 | 完整的 PEM 格式，包含 `-----BEGIN` 和 `-----END` |
| `APP_INSTALLATION_ID` | Installation ID | 纯数字，如：`12345678` |

#### 2. 验证私钥格式

私钥应该包含以下格式：
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
... (中间内容) ...
-----END RSA PRIVATE KEY-----
```

**常见问题：**
- ❌ 缺少 `-----BEGIN RSA PRIVATE KEY-----`
- ❌ 缺少 `-----END RSA PRIVATE KEY-----`
- ❌ 包含额外的空格或换行符
- ❌ 私钥内容被截断

#### 3. 重新生成私钥

如果私钥有问题，请按以下步骤重新生成：

1. 访问 GitHub App 设置页面
2. 点击 "Generate new private key"
3. 下载新的 `.pem` 文件
4. 复制完整的私钥内容（包括开始和结束标记）
5. 更新 `APP_PRIVATE_KEY` Secret

#### 4. 运行调试工作流

使用我们提供的调试工作流来诊断问题：

1. 在仓库中手动触发 `.github/workflows/debug-jwt.yml`
2. 查看详细的调试输出
3. 根据输出信息修复问题

## 🔍 调试步骤

### 步骤 1: 检查 Secrets 配置

```bash
# 在调试工作流中运行
echo "APP_ID: ${{ secrets.APP_ID }}"
echo "APP_INSTALLATION_ID: ${{ secrets.APP_INSTALLATION_ID }}"
echo "PRIVATE_KEY 长度: ${#PRIVATE_KEY}"
```

### 步骤 2: 验证私钥格式

```bash
# 检查私钥是否包含正确的标记
if [[ "$PRIVATE_KEY" =~ "-----BEGIN RSA PRIVATE KEY-----" ]]; then
  echo "✅ 私钥包含正确的开始标记"
else
  echo "❌ 私钥缺少开始标记"
fi
```

### 步骤 3: 测试私钥有效性

```bash
# 使用 OpenSSL 验证私钥
echo "$PRIVATE_KEY" > /tmp/test_key.pem
chmod 600 /tmp/test_key.pem
openssl rsa -in /tmp/test_key.pem -check -noout
```

### 步骤 4: 生成 JWT

```bash
# 生成 JWT 的各个部分
HEADER_JSON='{"alg":"RS256","typ":"JWT"}'
HEADER=$(echo -n "$HEADER_JSON" | base64 -w 0 | tr -d '=' | tr '/+' '_-')

PAYLOAD_JSON="{\"iat\":$NOW,\"exp\":$EXPIRES,\"iss\":\"$APP_ID\"}"
PAYLOAD=$(echo -n "$PAYLOAD_JSON" | base64 -w 0 | tr -d '=' | tr '/+' '_-')

SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign /tmp/test_key.pem | base64 -w 0 | tr -d '=' | tr '/+' '_-')
```

## 🛠️ 修复工具

### 1. 自动修复脚本

如果私钥格式有问题，可以使用以下脚本清理：

```bash
# 清理私钥格式
CLEANED_KEY=$(echo "$PRIVATE_KEY" | sed 's/\\n/\n/g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
```

### 2. 验证脚本

```bash
# 验证 JWT 格式
JWT_PARTS=$(echo "$JWT" | tr '.' '\n' | wc -l)
if [ "$JWT_PARTS" -ne 3 ]; then
  echo "❌ JWT 格式错误，应该有3个部分，实际有 $JWT_PARTS 个部分"
  exit 1
fi
```

## 📋 检查清单

在配置 GitHub App 时，请确保：

- [ ] GitHub App 已正确创建
- [ ] App ID 已记录并配置到 Secrets
- [ ] 私钥已生成并完整复制到 Secrets
- [ ] Installation ID 已获取并配置到 Secrets
- [ ] App 已安装到目标仓库
- [ ] App 具有必要的权限（Contents: Read, Actions: Read）

## 🎯 快速修复

如果问题仍然存在，请按以下顺序尝试：

1. **重新生成私钥** - 在 GitHub App 设置中生成新的私钥
2. **清理私钥格式** - 确保私钥包含正确的开始和结束标记
3. **运行调试工作流** - 使用 `.github/workflows/debug-jwt.yml` 进行详细诊断
4. **检查 App 权限** - 确保 App 具有必要的权限
5. **重新安装 App** - 卸载并重新安装 GitHub App

## 📞 获取帮助

如果按照以上步骤仍然无法解决问题，请：

1. 运行调试工作流并保存输出日志
2. 检查 GitHub App 的设置页面
3. 确认所有 Secrets 都已正确配置
4. 查看 GitHub Actions 的详细错误日志

---

**注意：** 请确保不要在任何地方泄露私钥内容，私钥应该只存储在 GitHub Secrets 中。 