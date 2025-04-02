const { ethers } = require("hardhat");

async function main() {
    console.log("🚀 开始部署 QRCodeNFT 合约到 Sonic 网络...");
    console.log("📊 Sonic链特性: 10,000 TPS, 亚秒级确认, EVM兼容");
    console.log("💰 支持Fee Monetization - 开发者可获得90%费用收益");

    // 获取部署者账户
    const [deployer] = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    
    console.log("🔗 网络信息:");
    console.log("  - 网络名称:", network.name);
    console.log("  - 链ID:", network.chainId);
    console.log("  - 部署账户:", deployer.address);
    console.log("  - 账户余额:", ethers.utils.formatEther(await deployer.getBalance()), "S");

    // 合约参数
    const NAME = "QR Code NFT";
    const SYMBOL = "QRNFT";

    // 获取合约工厂
    const QRCodeNFT = await ethers.getContractFactory("QRCodeNFT");
    
    console.log("正在部署合约...");
    console.log("合约名称:", NAME);
    console.log("合约符号:", SYMBOL);

    // 部署合约
    const qrCodeNFT = await QRCodeNFT.deploy(NAME, SYMBOL);
    
    console.log("等待合约部署确认...");
    await qrCodeNFT.deployed();

    console.log("✅ 合约部署成功!");
    console.log("合约地址:", qrCodeNFT.address);
    console.log("部署交易哈希:", qrCodeNFT.deployTransaction.hash);

    // 验证合约初始状态
    console.log("\n🔍 验证合约初始状态:");
    console.log("合约名称:", await qrCodeNFT.name());
    console.log("合约符号:", await qrCodeNFT.symbol());
    console.log("合约所有者:", await qrCodeNFT.owner());
    console.log("铸造费用:", ethers.utils.formatEther(await qrCodeNFT.mintFee()), "S");
    console.log("最大供应量:", await qrCodeNFT.maxSupply());
    console.log("当前供应量:", await qrCodeNFT.getCurrentSupply());
    console.log("剩余供应量:", await qrCodeNFT.getRemainingSupply());

    // 保存部署信息到文件
    const deploymentInfo = {
        network: "sonic",
        contractName: "QRCodeNFT",
        contractAddress: qrCodeNFT.address,
        deployerAddress: deployer.address,
        deploymentTx: qrCodeNFT.deployTransaction.hash,
        deploymentTime: new Date().toISOString(),
        contractParams: {
            name: NAME,
            symbol: SYMBOL
        },
        initialSettings: {
            mintFee: ethers.utils.formatEther(await qrCodeNFT.mintFee()),
            maxSupply: (await qrCodeNFT.maxSupply()).toString(),
            maxMintPerTx: (await qrCodeNFT.maxMintPerTx()).toString(),
            maxContentLength: (await qrCodeNFT.maxContentLength()).toString(),
            maxHoldingPerUser: (await qrCodeNFT.maxHoldingPerUser()).toString()
        }
    };

    const fs = require("fs");
    const path = require("path");
    
    // 确保 deployments 目录存在
    const deploymentsDir = path.join(__dirname, "../deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir);
    }

    // 保存部署信息
    const deploymentPath = path.join(deploymentsDir, `QRCodeNFT-${Date.now()}.json`);
    fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
    console.log("部署信息已保存到:", deploymentPath);

    // 输出用于前端的配置
    console.log("\n📋 前端配置信息:");
    console.log("CONTRACT_ADDRESS:", qrCodeNFT.address);
    console.log("NETWORK: Sonic");
    console.log("MINT_FEE:", ethers.utils.formatEther(await qrCodeNFT.mintFee()), "S");

    // Sonic链特有的优化建议
    console.log("\n⚡ Sonic链优化建议:");
    console.log("1. 利用10,000 TPS处理能力进行批量操作");
    console.log("2. 亚秒级确认提供更好的用户体验");
    console.log("3. 申请Fee Monetization计划获得90%费用收益");
    console.log("4. 使用Sonic Gateway桥接以太坊资产");

    // 如果是测试网，可以进行一些基本测试
    if (network.chainId === 57054) { // Sonic测试网链ID
        console.log("\n🧪 在Sonic测试网执行基本功能测试...");
        
        try {
            // 测试设置参数
            console.log("测试管理员权限...");
            const newFee = ethers.utils.parseEther("0.02");
            await qrCodeNFT.setMintFee(newFee);
            console.log("✅ 铸造费用设置成功:", ethers.utils.formatEther(newFee), "S");

            // 测试暂停功能
            console.log("测试合约暂停功能...");
            await qrCodeNFT.pause();
            console.log("✅ 合约暂停成功");
            
            await qrCodeNFT.unpause();
            console.log("✅ 合约恢复成功");

            // 重置费用
            await qrCodeNFT.setMintFee(ethers.utils.parseEther("0.01"));
            console.log("✅ 费用重置为0.01 S");

            console.log("🎉 所有Sonic测试网功能测试通过!");
        } catch (error) {
            console.error("❌ 测试失败:", error.message);
        }
    }

    console.log("\n🚀 部署完成! 合约已准备就绪。");
    console.log("请将合约地址添加到您的前端配置中:", qrCodeNFT.address);
}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("部署失败:", error);
        process.exit(1);
    }); 