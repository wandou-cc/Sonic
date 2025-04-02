const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("QRCodeNFT", function () {
    let QRCodeNFT;
    let qrCodeNFT;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    const NAME = "QR Code NFT";
    const SYMBOL = "QRNFT";
    const MINT_FEE = ethers.utils.parseEther("0.01");
    const CONTENT_1 = "Hello, World!";
    const TITLE_1 = "My First QR NFT";
    const DESCRIPTION_1 = "This is my first QR code NFT";
    const METADATA_URI_1 = "ipfs://QmTest123";

    beforeEach(async function () {
        // 获取测试账户
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        // 部署合约
        QRCodeNFT = await ethers.getContractFactory("QRCodeNFT");
        qrCodeNFT = await QRCodeNFT.deploy(NAME, SYMBOL);
        await qrCodeNFT.deployed();
    });

    describe("部署", function () {
        it("应该正确设置名称和符号", async function () {
            expect(await qrCodeNFT.name()).to.equal(NAME);
            expect(await qrCodeNFT.symbol()).to.equal(SYMBOL);
        });

        it("应该设置正确的默认值", async function () {
            expect(await qrCodeNFT.mintFee()).to.equal(MINT_FEE);
            expect(await qrCodeNFT.maxSupply()).to.equal(1000000);
            expect(await qrCodeNFT.maxMintPerTx()).to.equal(10);
            expect(await qrCodeNFT.maxContentLength()).to.equal(1000);
            expect(await qrCodeNFT.maxHoldingPerUser()).to.equal(100);
        });

        it("应该设置正确的owner", async function () {
            expect(await qrCodeNFT.owner()).to.equal(owner.address);
        });

        it("当前供应量应该为0", async function () {
            expect(await qrCodeNFT.getCurrentSupply()).to.equal(0);
        });
    });

    describe("铸造功能", function () {
        describe("单个铸造", function () {
            it("应该成功铸造NFT", async function () {
                const tx = await qrCodeNFT.connect(addr1).mint(
                    CONTENT_1,
                    TITLE_1,
                    DESCRIPTION_1,
                    METADATA_URI_1,
                    { value: MINT_FEE }
                );

                await expect(tx)
                    .to.emit(qrCodeNFT, "QRNFTMinted")
                    .withArgs(1, addr1.address, CONTENT_1, TITLE_1, METADATA_URI_1);

                expect(await qrCodeNFT.ownerOf(1)).to.equal(addr1.address);
                expect(await qrCodeNFT.getCurrentSupply()).to.equal(1);
                expect(await qrCodeNFT.userHoldings(addr1.address)).to.equal(1);
                expect(await qrCodeNFT.creatorCounts(addr1.address)).to.equal(1);
            });

            it("应该正确存储QR数据", async function () {
                await qrCodeNFT.connect(addr1).mint(
                    CONTENT_1,
                    TITLE_1,
                    DESCRIPTION_1,
                    METADATA_URI_1,
                    { value: MINT_FEE }
                );

                const qrData = await qrCodeNFT.getQRData(1);
                expect(qrData.content).to.equal(CONTENT_1);
                expect(qrData.title).to.equal(TITLE_1);
                expect(qrData.description).to.equal(DESCRIPTION_1);
                expect(qrData.creator).to.equal(addr1.address);
                expect(qrData.views).to.equal(0);
                expect(qrData.isActive).to.equal(true);
            });

            it("支付不足时应该失败", async function () {
                await expect(
                    qrCodeNFT.connect(addr1).mint(
                        CONTENT_1,
                        TITLE_1,
                        DESCRIPTION_1,
                        METADATA_URI_1,
                        { value: ethers.utils.parseEther("0.005") }
                    )
                ).to.be.revertedWith("QRCodeNFT: Insufficient payment");
            });

            it("空内容时应该失败", async function () {
                await expect(
                    qrCodeNFT.connect(addr1).mint(
                        "",
                        TITLE_1,
                        DESCRIPTION_1,
                        METADATA_URI_1,
                        { value: MINT_FEE }
                    )
                ).to.be.revertedWith("QRCodeNFT: Content cannot be empty");
            });

            it("空标题时应该失败", async function () {
                await expect(
                    qrCodeNFT.connect(addr1).mint(
                        CONTENT_1,
                        "",
                        DESCRIPTION_1,
                        METADATA_URI_1,
                        { value: MINT_FEE }
                    )
                ).to.be.revertedWith("QRCodeNFT: Title cannot be empty");
            });

            it("空元数据URI时应该失败", async function () {
                await expect(
                    qrCodeNFT.connect(addr1).mint(
                        CONTENT_1,
                        TITLE_1,
                        DESCRIPTION_1,
                        "",
                        { value: MINT_FEE }
                    )
                ).to.be.revertedWith("QRCodeNFT: Metadata URI cannot be empty");
            });

            it("重复内容时应该失败", async function () {
                await qrCodeNFT.connect(addr1).mint(
                    CONTENT_1,
                    TITLE_1,
                    DESCRIPTION_1,
                    METADATA_URI_1,
                    { value: MINT_FEE }
                );

                await expect(
                    qrCodeNFT.connect(addr2).mint(
                        CONTENT_1,
                        "Different Title",
                        "Different Description",
                        "ipfs://QmDifferent",
                        { value: MINT_FEE }
                    )
                ).to.be.revertedWith("QRCodeNFT: Content already exists");
            });

            it("内容过长时应该失败", async function () {
                const longContent = "a".repeat(1001);
                await expect(
                    qrCodeNFT.connect(addr1).mint(
                        longContent,
                        TITLE_1,
                        DESCRIPTION_1,
                        METADATA_URI_1,
                        { value: MINT_FEE }
                    )
                ).to.be.revertedWith("QRCodeNFT: Content too long");
            });
        });

        describe("批量铸造", function () {
            it("应该成功批量铸造NFT", async function () {
                const contents = ["Content 1", "Content 2", "Content 3"];
                const titles = ["Title 1", "Title 2", "Title 3"];
                const descriptions = ["Desc 1", "Desc 2", "Desc 3"];
                const metadataURIs = ["ipfs://1", "ipfs://2", "ipfs://3"];

                const tx = await qrCodeNFT.connect(addr1).batchMint(
                    contents,
                    titles,
                    descriptions,
                    metadataURIs,
                    { value: MINT_FEE.mul(3) }
                );

                expect(await qrCodeNFT.getCurrentSupply()).to.equal(3);
                expect(await qrCodeNFT.userHoldings(addr1.address)).to.equal(3);
                expect(await qrCodeNFT.creatorCounts(addr1.address)).to.equal(3);

                // 检查每个NFT的所有权
                for (let i = 1; i <= 3; i++) {
                    expect(await qrCodeNFT.ownerOf(i)).to.equal(addr1.address);
                }
            });

            it("数组长度不匹配时应该失败", async function () {
                const contents = ["Content 1", "Content 2"];
                const titles = ["Title 1"];
                const descriptions = ["Desc 1", "Desc 2"];
                const metadataURIs = ["ipfs://1", "ipfs://2"];

                await expect(
                    qrCodeNFT.connect(addr1).batchMint(
                        contents,
                        titles,
                        descriptions,
                        metadataURIs,
                        { value: MINT_FEE.mul(2) }
                    )
                ).to.be.revertedWith("QRCodeNFT: Arrays length mismatch");
            });

            it("支付不足时应该失败", async function () {
                const contents = ["Content 1", "Content 2"];
                const titles = ["Title 1", "Title 2"];
                const descriptions = ["Desc 1", "Desc 2"];
                const metadataURIs = ["ipfs://1", "ipfs://2"];

                await expect(
                    qrCodeNFT.connect(addr1).batchMint(
                        contents,
                        titles,
                        descriptions,
                        metadataURIs,
                        { value: MINT_FEE }
                    )
                ).to.be.revertedWith("QRCodeNFT: Insufficient payment");
            });

            it("超过单次最大铸造数量时应该失败", async function () {
                const contents = new Array(11).fill("Content");
                const titles = new Array(11).fill("Title");
                const descriptions = new Array(11).fill("Description");
                const metadataURIs = new Array(11).fill("ipfs://test");

                await expect(
                    qrCodeNFT.connect(addr1).batchMint(
                        contents,
                        titles,
                        descriptions,
                        metadataURIs,
                        { value: MINT_FEE.mul(11) }
                    )
                ).to.be.revertedWith("QRCodeNFT: Exceeds max mint per transaction");
            });
        });
    });

    describe("查看功能", function () {
        beforeEach(async function () {
            await qrCodeNFT.connect(addr1).mint(
                CONTENT_1,
                TITLE_1,
                DESCRIPTION_1,
                METADATA_URI_1,
                { value: MINT_FEE }
            );
        });

        it("应该返回正确的内容并增加查看次数", async function () {
            const content = await qrCodeNFT.connect(addr2).getContent(1);
            expect(content).to.equal(CONTENT_1);

            const qrData = await qrCodeNFT.getQRData(1);
            expect(qrData.views).to.equal(1);
        });

        it("应该正确记录查看事件", async function () {
            await expect(qrCodeNFT.connect(addr2).getContent(1))
                .to.emit(qrCodeNFT, "QRNFTViewed")
                .withArgs(1, addr2.address, 1);
        });

        it("不存在的tokenId应该失败", async function () {
            await expect(
                qrCodeNFT.getContent(999)
            ).to.be.revertedWith("QRCodeNFT: Token does not exist");
        });
    });

    describe("查询功能", function () {
        beforeEach(async function () {
            // addr1 创建 2 个NFT
            await qrCodeNFT.connect(addr1).mint(
                "Content 1",
                "Title 1",
                "Description 1",
                "ipfs://1",
                { value: MINT_FEE }
            );
            await qrCodeNFT.connect(addr1).mint(
                "Content 2",
                "Title 2",
                "Description 2",
                "ipfs://2",
                { value: MINT_FEE }
            );

            // addr2 创建 1 个NFT
            await qrCodeNFT.connect(addr2).mint(
                "Content 3",
                "Title 3",
                "Description 3",
                "ipfs://3",
                { value: MINT_FEE }
            );

            // 转移一个NFT给addr2
            await qrCodeNFT.connect(addr1).transferFrom(addr1.address, addr2.address, 1);
        });

        it("应该正确返回创建者的NFT", async function () {
            const addr1Tokens = await qrCodeNFT.getTokensByCreator(addr1.address);
            const addr2Tokens = await qrCodeNFT.getTokensByCreator(addr2.address);

            expect(addr1Tokens.length).to.equal(2);
            expect(addr1Tokens[0]).to.equal(1);
            expect(addr1Tokens[1]).to.equal(2);

            expect(addr2Tokens.length).to.equal(1);
            expect(addr2Tokens[0]).to.equal(3);
        });

        it("应该正确返回持有者的NFT", async function () {
            const addr1Owned = await qrCodeNFT.getTokensByOwner(addr1.address);
            const addr2Owned = await qrCodeNFT.getTokensByOwner(addr2.address);

            expect(addr1Owned.length).to.equal(1);
            expect(addr1Owned[0]).to.equal(2);

            expect(addr2Owned.length).to.equal(2);
            expect(addr2Owned).to.include(1);
            expect(addr2Owned).to.include(3);
        });

        it("应该正确检查内容是否存在", async function () {
            expect(await qrCodeNFT.isContentExists("Content 1")).to.equal(true);
            expect(await qrCodeNFT.isContentExists("Non-existent")).to.equal(false);
        });

        it("应该正确返回合约统计信息", async function () {
            const stats = await qrCodeNFT.getContractStats();
            expect(stats.totalSupply).to.equal(3);
            expect(stats.maxTotalSupply).to.equal(1000000);
            expect(stats.currentMintFee).to.equal(MINT_FEE);
            expect(stats.totalBalance).to.equal(MINT_FEE.mul(3));
        });
    });

    describe("管理员功能", function () {
        it("只有owner可以设置铸造费用", async function () {
            const newFee = ethers.utils.parseEther("0.02");
            await expect(qrCodeNFT.connect(owner).setMintFee(newFee))
                .to.emit(qrCodeNFT, "MintFeeUpdated")
                .withArgs(MINT_FEE, newFee);

            expect(await qrCodeNFT.mintFee()).to.equal(newFee);

            await expect(
                qrCodeNFT.connect(addr1).setMintFee(newFee)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("应该能够设置最大供应量", async function () {
            const newMaxSupply = 2000000;
            await expect(qrCodeNFT.connect(owner).setMaxSupply(newMaxSupply))
                .to.emit(qrCodeNFT, "MaxSupplyUpdated")
                .withArgs(1000000, newMaxSupply);

            expect(await qrCodeNFT.maxSupply()).to.equal(newMaxSupply);
        });

        it("不能设置过低的最大供应量", async function () {
            // 先铸造一个NFT
            await qrCodeNFT.connect(addr1).mint(
                CONTENT_1,
                TITLE_1,
                DESCRIPTION_1,
                METADATA_URI_1,
                { value: MINT_FEE }
            );

            await expect(
                qrCodeNFT.connect(owner).setMaxSupply(0)
            ).to.be.revertedWith("QRCodeNFT: New max supply too low");
        });

        it("应该能够暂停和恢复合约", async function () {
            await qrCodeNFT.connect(owner).pause();
            expect(await qrCodeNFT.paused()).to.equal(true);

            await expect(
                qrCodeNFT.connect(addr1).mint(
                    CONTENT_1,
                    TITLE_1,
                    DESCRIPTION_1,
                    METADATA_URI_1,
                    { value: MINT_FEE }
                )
            ).to.be.revertedWith("Pausable: paused");

            await qrCodeNFT.connect(owner).unpause();
            expect(await qrCodeNFT.paused()).to.equal(false);

            // 现在应该可以正常铸造
            await qrCodeNFT.connect(addr1).mint(
                CONTENT_1,
                TITLE_1,
                DESCRIPTION_1,
                METADATA_URI_1,
                { value: MINT_FEE }
            );
        });

        it("应该能够提取资金", async function () {
            // 先铸造几个NFT产生资金
            await qrCodeNFT.connect(addr1).mint(
                CONTENT_1,
                TITLE_1,
                DESCRIPTION_1,
                METADATA_URI_1,
                { value: MINT_FEE }
            );

            const initialBalance = await owner.getBalance();
            const contractBalance = await ethers.provider.getBalance(qrCodeNFT.address);

            await expect(qrCodeNFT.connect(owner).withdraw())
                .to.emit(qrCodeNFT, "FundsWithdrawn")
                .withArgs(owner.address, contractBalance);

            expect(await ethers.provider.getBalance(qrCodeNFT.address)).to.equal(0);
        });
    });

    describe("NFT状态管理", function () {
        beforeEach(async function () {
            await qrCodeNFT.connect(addr1).mint(
                CONTENT_1,
                TITLE_1,
                DESCRIPTION_1,
                METADATA_URI_1,
                { value: MINT_FEE }
            );
        });

        it("NFT所有者应该能够切换状态", async function () {
            await expect(qrCodeNFT.connect(addr1).toggleTokenStatus(1))
                .to.emit(qrCodeNFT, "QRNFTStatusChanged")
                .withArgs(1, false);

            const qrData = await qrCodeNFT.getQRData(1);
            expect(qrData.isActive).to.equal(false);

            // 再次切换
            await qrCodeNFT.connect(addr1).toggleTokenStatus(1);
            const qrData2 = await qrCodeNFT.getQRData(1);
            expect(qrData2.isActive).to.equal(true);
        });

        it("非所有者不能切换状态", async function () {
            await expect(
                qrCodeNFT.connect(addr2).toggleTokenStatus(1)
            ).to.be.revertedWith("QRCodeNFT: Not authorized to change status");
        });

        it("owner应该能够切换任何NFT的状态", async function () {
            await expect(qrCodeNFT.connect(owner).toggleTokenStatus(1))
                .to.emit(qrCodeNFT, "QRNFTStatusChanged")
                .withArgs(1, false);
        });
    });

    describe("限制检查", function () {
        it("应该正确检查用户持有量限制", async function () {
            // 设置较小的持有量限制进行测试
            await qrCodeNFT.connect(owner).setMaxHoldingPerUser(2);

            // 铸造2个NFT
            await qrCodeNFT.connect(addr1).mint(
                "Content 1",
                "Title 1",
                "Description 1",
                "ipfs://1",
                { value: MINT_FEE }
            );
            await qrCodeNFT.connect(addr1).mint(
                "Content 2",
                "Title 2",
                "Description 2",
                "ipfs://2",
                { value: MINT_FEE }
            );

            // 第3个应该失败
            await expect(
                qrCodeNFT.connect(addr1).mint(
                    "Content 3",
                    "Title 3",
                    "Description 3",
                    "ipfs://3",
                    { value: MINT_FEE }
                )
            ).to.be.revertedWith("QRCodeNFT: Exceeds max holding per user");
        });

        it("应该正确检查最大供应量限制", async function () {
            await qrCodeNFT.connect(owner).setMaxSupply(1);

            await qrCodeNFT.connect(addr1).mint(
                CONTENT_1,
                TITLE_1,
                DESCRIPTION_1,
                METADATA_URI_1,
                { value: MINT_FEE }
            );

            await expect(
                qrCodeNFT.connect(addr2).mint(
                    "Content 2",
                    "Title 2",
                    "Description 2",
                    "ipfs://2",
                    { value: MINT_FEE }
                )
            ).to.be.revertedWith("QRCodeNFT: Exceeds max supply");
        });
    });

    describe("边界情况", function () {
        it("应该正确处理零地址查询", async function () {
            await expect(
                qrCodeNFT.getTokensByCreator(ethers.constants.AddressZero)
            ).to.be.revertedWith("QRCodeNFT: Invalid creator address");

            await expect(
                qrCodeNFT.getTokensByOwner(ethers.constants.AddressZero)
            ).to.be.revertedWith("QRCodeNFT: Invalid owner address");
        });

        it("应该正确处理没有NFT的用户查询", async function () {
            const tokens = await qrCodeNFT.getTokensByCreator(addr1.address);
            expect(tokens.length).to.equal(0);

            const ownedTokens = await qrCodeNFT.getTokensByOwner(addr1.address);
            expect(ownedTokens.length).to.equal(0);
        });

        it("应该正确处理空数组的批量铸造", async function () {
            await expect(
                qrCodeNFT.connect(addr1).batchMint([], [], [], [], { value: 0 })
            ).to.be.revertedWith("QRCodeNFT: Amount must be greater than 0");
        });
    });
}); 