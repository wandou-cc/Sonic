# QR-NFT on Sonic Chain 🎯

基于Sonic区块链的二维码NFT项目 - 让用户mint包含自定义内容的二维码NFT

## 🌟 项目特色

- **高性能**: 基于Sonic链，享受10,000 TPS和亚秒级确认
- **EVM兼容**: 完全兼容以太坊生态系统
- **创新功能**: 可扫描的二维码NFT，包含自定义内容
- **费用优化**: 支持Sonic的Fee Monetization计划
- **安全可靠**: 完整的测试覆盖和安全审计

## 🚀 Sonic链优势

- **超高TPS**: 10,000笔交易/秒
- **亚秒确认**: 极快的交易确认时间
- **低成本**: 相比以太坊大幅降低Gas费用
- **Fee Monetization**: 开发者可获得90%的费用收益
- **Sonic Gateway**: 安全桥接以太坊资产

## 🛠 技术栈

- **区块链**: Sonic Network
- **智能合约**: Solidity ^0.8.19
- **开发框架**: Hardhat
- **测试框架**: Chai + Mocha
- **标准**: ERC721 (OpenZeppelin)

## 📋 合约功能

### 核心功能
- ✅ 铸造二维码NFT
- ✅ 批量铸造支持
- ✅ 内容查看和统计
- ✅ 防重复内容机制
- ✅ 用户持有量限制

### 管理功能
- ✅ 费用管理
- ✅ 供应量控制
- ✅ 合约暂停/恢复
- ✅ 资金提取

### 安全特性
- ✅ 重入攻击防护
- ✅ 权限控制
- ✅ 输入验证
- ✅ 异常处理

## 🔧 快速开始

### 环境要求

- Node.js >= 16.0.0
- npm 或 yarn
- Sonic钱包 (MetaMask配置Sonic网络)

### 安装依赖

```bash
# 克隆项目
git clone https://github.com/your-username/qr-nft-sonic.git
cd qr-nft-sonic

# 安装依赖
npm install
```

### 环境配置

1. 复制环境变量文件:
```bash
cp env.example .env
```

2. 配置您的私钥和其他参数:
```bash
# .env 文件
PRIVATE_KEY=your_private_key_here
SONIC_RPC_URL=https://rpc.soniclabs.com
SONIC_TESTNET_RPC_URL=https://rpc.blaze.soniclabs.com
```

### 编译合约

```bash
npm run compile
```

### 运行测试

```bash
# 运行所有测试
npm run test

# 运行测试并生成Gas报告
npm run test:gas

# 运行测试覆盖率
npm run coverage
```

## 🌐 网络配置

### Sonic主网
- **网络名称**: Sonic
- **RPC URL**: https://rpc.soniclabs.com
- **链ID**: 146
- **货币符号**: S
- **区块浏览器**: https://sonicscan.org

### Sonic测试网 (Blaze)
- **网络名称**: Sonic Testnet
- **RPC URL**: https://rpc.blaze.soniclabs.com
- **链ID**: 57054
- **货币符号**: S
- **区块浏览器**: https://testnet.sonicscan.org

## 🚀 部署

### 测试网部署

```bash
# 部署到Sonic测试网
npm run deploy:testnet
```

### 主网部署

```bash
# 部署到Sonic主网
npm run deploy:mainnet
```

### 合约验证

```bash
# 验证测试网合约
npm run verify:testnet <CONTRACT_ADDRESS>

# 验证主网合约
npm run verify:mainnet <CONTRACT_ADDRESS>
```

## 📊 合约接口

### 铸造功能

```solidity
// 铸造单个NFT
function mint(
    string memory content,
    string memory title,
    string memory description,
    string memory metadataURI
) external payable returns (uint256);

// 批量铸造NFT
function batchMint(
    string[] memory contents,
    string[] memory titles,
    string[] memory descriptions,
    string[] memory metadataURIs
) external payable returns (uint256[] memory);
```

### 查询功能

```solidity
// 获取二维码内容
function getContent(uint256 tokenId) external returns (string memory);

// 获取NFT完整数据
function getQRData(uint256 tokenId) external view returns (QRData memory);

// 获取用户创建的NFT
function getTokensByCreator(address creator) external view returns (uint256[] memory);

// 获取用户持有的NFT
function getTokensByOwner(address owner) external view returns (uint256[] memory);
```

## 💰 费用结构

- **铸造费用**: 0.1 S (可调整)
- **批量铸造**: 0.08 S × 数量 (批量优惠)
- **高级功能**: 0.5 S
- **Fee Monetization**: 90%归开发者，10%作为奖励池

## 🎯 使用场景

1. **个人名片**: 创建包含联系信息的二维码NFT
2. **活动门票**: 可验证的数字门票
3. **产品溯源**: 商品信息的区块链记录
4. **艺术收藏**: 独特的二维码艺术品
5. **社交媒体**: 可扫描的社交链接

## 🔐 安全考虑

- 合约经过全面测试
- 实现了重入攻击防护
- 权限控制和输入验证
- 建议进行第三方安全审计

## 📈 Gas优化

- 批量操作减少Gas成本
- 高效的存储结构
- 优化的合约函数
- 利用Sonic链的低Gas费用

## 🤝 贡献指南

1. Fork项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情

## 🔗 相关链接

- [Sonic官方文档](https://docs.soniclabs.com)
- [Sonic构建指南](https://docs.soniclabs.com/sonic/build-on-sonic)
- [Fee Monetization](https://docs.soniclabs.com/funding/fee-monetization)
- [Sonic Gateway](https://docs.soniclabs.com/sonic/sonic-gateway)

## 📞 联系我们

- 项目维护者: QR-NFT Team
- 邮箱: contact@qr-nft.com
- 技术支持: support@qr-nft.com

## 🎉 致谢

感谢Sonic Labs提供的高性能区块链基础设施和开发者支持！

---

**⚡ 在Sonic链上构建，享受10,000 TPS的极速体验！** 