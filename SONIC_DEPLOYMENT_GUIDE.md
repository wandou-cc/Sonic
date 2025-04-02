# Sonic链部署指南 ⚡

本指南将帮助您在Sonic区块链上成功部署QR-NFT项目，并充分利用Sonic链的特性。

## 🌟 Sonic链特性概览

根据[Sonic官方文档](https://docs.soniclabs.com/sonic/build-on-sonic)，Sonic提供：

- **超高性能**: 10,000 TPS处理能力
- **亚秒级确认**: 极快的交易确认时间
- **完全EVM兼容**: 无需修改智能合约代码
- **Fee Monetization**: 开发者可获得90%的费用收益
- **Sonic Gateway**: 与以太坊的安全桥接

## 🚀 预部署准备

### 1. 配置Sonic网络

在MetaMask中添加Sonic网络：

**Sonic主网**
```
网络名称: Sonic
RPC URL: https://rpc.soniclabs.com
链ID: 146
货币符号: S
区块链浏览器: https://sonicscan.org
```

**Sonic测试网 (Blaze)**
```
网络名称: Sonic Testnet
RPC URL: https://rpc.blaze.soniclabs.com
链ID: 57054
货币符号: S
区块链浏览器: https://testnet.sonicscan.org
```

### 2. 获取测试代币

1. 访问 [Sonic测试网水龙头](https://faucet.soniclabs.com)
2. 输入您的钱包地址
3. 获得测试用的S代币

### 3. 环境变量配置

创建`.env`文件：
```bash
# 基础配置
PRIVATE_KEY=your_private_key_here
NODE_ENV=development

# Sonic网络配置
SONIC_RPC_URL=https://rpc.soniclabs.com
SONIC_TESTNET_RPC_URL=https://rpc.blaze.soniclabs.com

# 合约参数
CONTRACT_NAME="QR Code NFT"
CONTRACT_SYMBOL="QRNFT"
MINT_FEE_ETHER=0.01
```

## 📋 部署步骤

### 步骤1: 安装依赖
```bash
npm install
```

### 步骤2: 编译合约
```bash
npm run compile
```

### 步骤3: 运行测试
```bash
# 本地测试
npm run test

# 生成Gas报告
npm run test:gas
```

### 步骤4: 部署到测试网
```bash
# 部署到Sonic测试网
npm run deploy:testnet
```

部署成功后，您将看到：
```
🚀 开始部署 QRCodeNFT 合约到 Sonic 网络...
📊 Sonic链特性: 10,000 TPS, 亚秒级确认, EVM兼容
💰 支持Fee Monetization - 开发者可获得90%费用收益

🔗 网络信息:
  - 网络名称: sonic-testnet
  - 链ID: 57054
  - 部署账户: 0x...
  - 账户余额: 1.0 S

✅ 合约部署成功!
合约地址: 0x...
```

### 步骤5: 验证合约
```bash
npm run verify:testnet 0x你的合约地址
```

### 步骤6: 部署到主网
```bash
# 确保有足够的S代币
npm run deploy:mainnet
```

## ⚡ Sonic链优化建议

### 1. 利用高TPS特性
- 批量铸造NFT以提高效率
- 用户可以快速连续操作而不用等待确认

### 2. 亚秒级确认优势
- 提供实时的用户体验
- 扫描二维码后立即显示内容

### 3. Fee Monetization申请
根据[Fee Monetization文档](https://docs.soniclabs.com/funding/fee-monetization)：

1. 访问申请页面
2. 提交项目信息
3. 获得90%费用收益资格

### 4. 成本优化
```solidity
// 利用Sonic的低Gas费用，可以设置更合理的铸造费用
// 建议: 0.01 S (约$0.01-0.1)
uint256 public mintFee = 0.01 ether;
```

## 🔧 合约交互示例

### 使用ethers.js
```javascript
const { ethers } = require("ethers");

// 连接到Sonic网络
const provider = new ethers.providers.JsonRpcProvider("https://rpc.soniclabs.com");
const wallet = new ethers.Wallet(privateKey, provider);

// 合约实例
const contract = new ethers.Contract(contractAddress, abi, wallet);

// 铸造NFT
const tx = await contract.mint(
    "Hello, Sonic World!",
    "我的第一个Sonic NFT",
    "这是在Sonic链上创建的二维码NFT",
    "ipfs://QmYourMetadataHash",
    { value: ethers.utils.parseEther("0.01") }
);

console.log("交易哈希:", tx.hash);
await tx.wait(); // 在Sonic上几乎立即确认
console.log("NFT铸造成功!");
```

### 批量操作示例
```javascript
// 利用Sonic的高TPS进行批量铸造
const contents = [
    "联系方式: contact@example.com",
    "个人网站: https://mysite.com",
    "社交媒体: @myhandle"
];

const tx = await contract.batchMint(
    contents,
    ["联系方式", "个人网站", "社交媒体"],
    ["我的联系方式", "我的个人网站", "我的社交媒体"],
    ["ipfs://hash1", "ipfs://hash2", "ipfs://hash3"],
    { value: ethers.utils.parseEther("0.03") } // 3 * 0.01 S
);
```

## 🎯 最佳实践

### 1. 智能合约优化
- 使用批量操作减少交易数量
- 优化存储结构以节省Gas
- 实现适当的错误处理

### 2. 前端优化
```javascript
// 利用Sonic的快速确认，减少loading时间
const mintNFT = async (content, title, description, metadataURI) => {
    const tx = await contract.mint(content, title, description, metadataURI, {
        value: ethers.utils.parseEther("0.01")
    });
    
    // 在Sonic上，通常1-2秒内确认
    const receipt = await tx.wait();
    return receipt;
};
```

### 3. 用户体验
- 显示实时的交易状态
- 利用快速确认提供即时反馈
- 提供批量操作选项

## 📊 性能监控

### 1. 交易监控
```javascript
// 监控交易性能
const startTime = Date.now();
const tx = await contract.mint(...);
await tx.wait();
const endTime = Date.now();
console.log(`交易确认时间: ${endTime - startTime}ms`);
```

### 2. Gas使用分析
```bash
# 生成详细的Gas报告
npm run test:gas
```

### 3. 合约统计
```javascript
// 获取合约统计信息
const stats = await contract.getContractStats();
console.log("总供应量:", stats.totalSupply.toString());
console.log("合约余额:", ethers.utils.formatEther(stats.totalBalance), "S");
```

## 🛡️ 安全检查清单

- [ ] 私钥安全存储
- [ ] 合约权限正确设置
- [ ] 输入验证完整实现
- [ ] 重入攻击防护已启用
- [ ] 测试覆盖率 > 90%
- [ ] 第三方安全审计（推荐）

## 🚨 常见问题解决

### 1. 连接问题
```javascript
// 检查网络连接
const network = await provider.getNetwork();
console.log("当前网络:", network.name, network.chainId);
```

### 2. Gas估算
```javascript
// 估算Gas费用
const gasEstimate = await contract.estimateGas.mint(...);
console.log("预估Gas:", gasEstimate.toString());
```

### 3. 交易失败
- 检查账户余额是否足够
- 确认网络连接稳定
- 验证合约地址正确

## 📈 后续优化

### 1. 申请Fee Monetization
- 收集用户数据和交易统计
- 准备项目文档和演示
- 提交申请获得90%费用收益

### 2. 集成Sonic生态
- 使用Sonic Gateway桥接资产
- 集成其他Sonic生态项目
- 参与Sonic社区活动

### 3. 扩展功能
- 添加NFT市场功能
- 实现跨链桥接
- 开发移动端应用

## 🎉 成功部署后

1. **记录合约地址**: 保存部署信息
2. **更新前端配置**: 配置正确的合约地址
3. **测试所有功能**: 确保一切正常运行
4. **监控合约状态**: 设置必要的监控
5. **准备推广**: 利用Sonic的高性能特性进行营销

---

## 📞 技术支持

如果在部署过程中遇到问题，可以：

1. 查看 [Sonic官方文档](https://docs.soniclabs.com)
2. 加入 [Sonic Discord社区](https://discord.gg/sonic)
3. 查看项目GitHub Issues
4. 联系技术支持团队

**祝您在Sonic链上构建成功！⚡** 