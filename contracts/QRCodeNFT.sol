// SPDX-License-Identifier: MIT
// 这行指定了合约的开源许可证类型，MIT 是一种非常宽松的许可证

pragma solidity ^0.8.19;
// 指定 Solidity 编译器版本，^0.8.19 表示使用 0.8.19 及以上但低于 0.9.0 的版本

// 导入 OpenZeppelin 库 - 这是一个经过安全审计的智能合约库
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";                    // ERC721 标准NFT实现
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // NFT元数据存储扩展
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // NFT枚举扩展，可以遍历所有NFT
import "@openzeppelin/contracts/security/Pausable.sol";                     // 暂停功能，紧急情况下可以暂停合约
import "@openzeppelin/contracts/access/Ownable.sol";                        // 拥有者权限管理
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";              // 防重入攻击保护
import "@openzeppelin/contracts/utils/Counters.sol";                        // 计数器工具，用于生成递增的tokenId
import "@openzeppelin/contracts/utils/Strings.sol";                         // 字符串处理工具

/**
 * @title QRCodeNFT - 二维码NFT合约
 * @dev 这是一个允许用户铸造包含自定义内容的二维码NFT的智能合约
 * 
 * 主要功能：
 * 1. 铸造包含二维码内容的NFT
 * 2. 防止重复内容
 * 3. 支持批量铸造
 * 4. 查看统计和管理功能
 * 5. 安全的资金管理
 * 
 * @author QR-NFT Team
 */
contract QRCodeNFT is 
    ERC721,              // 基础NFT功能
    ERC721URIStorage,    // 元数据存储功能  
    ERC721Enumerable,    // NFT枚举功能
    Pausable,            // 暂停功能
    Ownable,             // 拥有者权限
    ReentrancyGuard      // 防重入攻击
{
    // 使用库函数 - 这些库为特定类型添加了额外的功能
    using Counters for Counters.Counter;  // 为 Counter 类型添加自增功能
    using Strings for uint256;             // 为 uint256 添加转字符串功能

    // ================================
    // 状态变量 - 存储在区块链上的数据
    // ================================
    
    // 代币ID计数器，用于生成唯一的NFT编号
    Counters.Counter private _tokenIdCounter;
    
    // 铸造费用，针对Sonic网络优化 (1 S = 10^18 wei)
    uint256 public mintFee = 0.1 ether;
    
    // 最大供应量 - 限制总共能铸造的NFT数量
    uint256 public maxSupply = 1000000;
    
    // 单次交易最大铸造数量 - 防止一次性铸造过多导致gas费过高
    uint256 public maxMintPerTx = 10;
    
    // 二维码内容最大长度限制 - 防止存储过大的数据
    uint256 public maxContentLength = 1000;
    
    // 每个用户最大持有量 - 防止单个用户垄断
    uint256 public maxHoldingPerUser = 100;

    // ================================
    // 数据结构 - 定义复杂的数据类型
    // ================================
    
    /**
     * @dev QR码数据结构 - 存储每个NFT的详细信息
     */
    struct QRData {
        string content;          // 二维码原始内容（如网址、文本等）
        string title;           // NFT标题，显示名称
        string description;     // NFT描述，详细说明
        address creator;        // 创建者的钱包地址
        uint256 createdAt;      // 创建时间戳（Unix时间）
        uint256 views;          // 被查看的次数
        bool isActive;          // 是否处于激活状态
    }
    
    // ================================
    // 映射关系 - 类似于数据库中的键值对存储
    // ================================
    
    // tokenId => QRData : 通过NFT编号查找对应的QR码数据
    mapping(uint256 => QRData) public qrDataMap;
    
    // 用户地址 => 持有数量 : 记录每个用户持有的NFT数量
    mapping(address => uint256) public userHoldings;
    
    // 创建者地址 => 创建的NFT数量 : 记录每个用户创建的NFT数量
    mapping(address => uint256) public creatorCounts;
    
    // 内容哈希 => tokenId : 防止重复内容，通过内容哈希快速查找
    mapping(bytes32 => uint256) public contentHashToTokenId;

    // ================================
    // 事件定义 - 当特定操作发生时发出的通知
    // ================================
    
    /**
     * @dev 当成功铸造QR NFT时发出此事件
     */
    event QRNFTMinted(
        uint256 indexed tokenId,    // indexed 表示可以被过滤查询
        address indexed creator,
        string content,
        string title,
        string metadataURI
    );
    
    /**
     * @dev 当QR NFT被查看时发出此事件
     */
    event QRNFTViewed(
        uint256 indexed tokenId,
        address indexed viewer,
        uint256 viewCount
    );
    
    /**
     * @dev 当QR NFT状态改变时发出此事件
     */
    event QRNFTStatusChanged(
        uint256 indexed tokenId,
        bool isActive
    );
    
    /**
     * @dev 管理员操作相关事件
     */
    event MintFeeUpdated(uint256 oldFee, uint256 newFee);
    event MaxSupplyUpdated(uint256 oldSupply, uint256 newSupply);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // ================================
    // 修饰符 - 函数执行前的条件检查
    // ================================
    
    /**
     * @dev 检查tokenId是否存在
     * modifier 是一种特殊的函数，用于在其他函数执行前进行检查
     * _ 表示被修饰函数的代码在此处执行
     */
    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "QRCodeNFT: Token does not exist");
        _; // 在检查通过后，执行被修饰的函数
    }
    
    /**
     * @dev 检查内容是否有效
     */
    modifier validContent(string memory content) {
        require(bytes(content).length > 0, "QRCodeNFT: Content cannot be empty");
        require(bytes(content).length <= maxContentLength, "QRCodeNFT: Content too long");
        _;
    }
    
    /**
     * @dev 检查铸造数量是否有效
     */
    modifier validMintAmount(uint256 amount) {
        require(amount > 0, "QRCodeNFT: Amount must be greater than 0");
        require(amount <= maxMintPerTx, "QRCodeNFT: Exceeds max mint per transaction");
        _;
    }
    
    /**
     * @dev 检查是否超过最大供应量
     */
    modifier checkSupply(uint256 amount) {
        require(_tokenIdCounter.current() + amount <= maxSupply, "QRCodeNFT: Exceeds max supply");
        _;
    }
    
    /**
     * @dev 检查用户持有量是否超限
     */
    modifier checkUserHolding(address user, uint256 amount) {
        require(userHoldings[user] + amount <= maxHoldingPerUser, "QRCodeNFT: Exceeds max holding per user");
        _;
    }

    // ================================
    // 构造函数 - 合约部署时执行一次
    // ================================
    
    /**
     * @dev 构造函数，初始化NFT集合的名称和符号
     * @param name NFT集合名称（如 "QR Code NFTs"）
     * @param symbol NFT集合符号（如 "QRNFT"）
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        // 调用父合约ERC721的构造函数
        
        // tokenId从1开始计数（0通常表示不存在）
        _tokenIdCounter.increment();
    }

    // ================================
    // 核心功能函数 - 合约的主要业务逻辑
    // ================================
    
    /**
     * @dev 铸造单个QR NFT - 这是用户创建NFT的主要函数
     * @param content 二维码内容（网址、文本等）
     * @param title NFT标题
     * @param description NFT描述
     * @param metadataURI IPFS元数据URI（包含图片和属性信息）
     * @return 返回新铸造的tokenId
     */
    function mint(
        string memory content,
        string memory title,
        string memory description,
        string memory metadataURI
    ) 
        external                    // 外部函数，只能从合约外部调用
        payable                     // 可以接收以太币
        whenNotPaused              // 仅在合约未暂停时可用
        nonReentrant               // 防重入攻击
        validContent(content)       // 检查内容有效性
        checkSupply(1)             // 检查供应量
        checkUserHolding(msg.sender, 1)  // 检查用户持有量
        returns (uint256)          // 返回uint256类型的tokenId
    {
        // 检查支付的以太币是否足够
        require(msg.value >= mintFee, "QRCodeNFT: Insufficient payment");
        
        // 检查标题和元数据URI不能为空
        require(bytes(title).length > 0, "QRCodeNFT: Title cannot be empty");
        require(bytes(metadataURI).length > 0, "QRCodeNFT: Metadata URI cannot be empty");
        
        // 检查内容是否已存在（防止重复）
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        require(contentHashToTokenId[contentHash] == 0, "QRCodeNFT: Content already exists");
        
        // 获取新的tokenId并递增计数器
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // 铸造NFT到用户地址
        _safeMint(msg.sender, tokenId);
        
        // 设置NFT的元数据URI
        _setTokenURI(tokenId, metadataURI);
        
        // 存储QR数据
        qrDataMap[tokenId] = QRData({
            content: content,
            title: title,
            description: description,
            creator: msg.sender,
            createdAt: block.timestamp,  // 当前区块时间戳
            views: 0,
            isActive: true
        });
        
        // 更新映射关系
        contentHashToTokenId[contentHash] = tokenId;
        userHoldings[msg.sender]++;
        creatorCounts[msg.sender]++;
        
        // 发出事件通知
        emit QRNFTMinted(tokenId, msg.sender, content, title, metadataURI);
        
        return tokenId;
    }
    
    /**
     * @dev 批量铸造QR NFT - 一次性铸造多个NFT，节省gas费
     * @param contents 二维码内容数组
     * @param titles NFT标题数组
     * @param descriptions NFT描述数组
     * @param metadataURIs IPFS元数据URI数组
     * @return 返回所有新铸造的tokenId数组
     */
    function batchMint(
        string[] memory contents,
        string[] memory titles,
        string[] memory descriptions,
        string[] memory metadataURIs
    ) 
        external 
        payable 
        whenNotPaused
        nonReentrant
        validMintAmount(contents.length)
        checkSupply(contents.length)
        checkUserHolding(msg.sender, contents.length)
        returns (uint256[] memory) 
    {
        // 检查所有数组长度是否一致
        require(contents.length == titles.length, "QRCodeNFT: Arrays length mismatch");
        require(contents.length == descriptions.length, "QRCodeNFT: Arrays length mismatch");
        require(contents.length == metadataURIs.length, "QRCodeNFT: Arrays length mismatch");
        
        // 检查支付金额是否足够（数量 × 单价）
        require(msg.value >= mintFee * contents.length, "QRCodeNFT: Insufficient payment");
        
        // 创建用于存储tokenId的数组
        uint256[] memory tokenIds = new uint256[](contents.length);
        
        // 循环处理每个NFT
        for (uint256 i = 0; i < contents.length; i++) {
            // 验证每个内容的有效性
            require(bytes(contents[i]).length > 0, "QRCodeNFT: Content cannot be empty");
            require(bytes(contents[i]).length <= maxContentLength, "QRCodeNFT: Content too long");
            require(bytes(titles[i]).length > 0, "QRCodeNFT: Title cannot be empty");
            require(bytes(metadataURIs[i]).length > 0, "QRCodeNFT: Metadata URI cannot be empty");
            
            // 检查内容是否已存在
            bytes32 contentHash = keccak256(abi.encodePacked(contents[i]));
            require(contentHashToTokenId[contentHash] == 0, "QRCodeNFT: Duplicate content found");
            
            // 铸造NFT
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, metadataURIs[i]);
            
            // 存储数据
            qrDataMap[tokenId] = QRData({
                content: contents[i],
                title: titles[i],
                description: descriptions[i],
                creator: msg.sender,
                createdAt: block.timestamp,
                views: 0,
                isActive: true
            });
            
            contentHashToTokenId[contentHash] = tokenId;
            tokenIds[i] = tokenId;
            
            // 发出事件
            emit QRNFTMinted(tokenId, msg.sender, contents[i], titles[i], metadataURIs[i]);
        }
        
        // 更新用户数据
        userHoldings[msg.sender] += contents.length;
        creatorCounts[msg.sender] += contents.length;
        
        return tokenIds;
    }

    // ================================
    // 查看和查询函数 - 获取信息的只读函数
    // ================================
    
    /**
     * @dev 获取NFT的二维码内容 - 会增加查看次数
     * @param tokenId NFT ID
     * @return 返回二维码内容字符串
     */
    function getContent(uint256 tokenId) 
        external 
        validTokenId(tokenId) 
        returns (string memory) 
    {
        // 增加查看次数
        qrDataMap[tokenId].views++;
        
        // 发出查看事件
        emit QRNFTViewed(tokenId, msg.sender, qrDataMap[tokenId].views);
        
        return qrDataMap[tokenId].content;
    }
    
    /**
     * @dev 获取NFT的完整数据 (只读，不增加查看次数)
     * @param tokenId NFT ID
     * @return 返回完整的QRData结构
     */
    function getQRData(uint256 tokenId) 
        external 
        view                       // view 表示只读函数，不修改状态
        validTokenId(tokenId) 
        returns (QRData memory) 
    {
        return qrDataMap[tokenId];
    }
    
    /**
     * @dev 获取指定创建者的所有NFT
     * @param creator 创建者地址
     * @return 返回该创建者所有NFT的tokenId数组
     */
    function getTokensByCreator(address creator) 
        external 
        view 
        returns (uint256[] memory) 
    {
        require(creator != address(0), "QRCodeNFT: Invalid creator address");
        
        uint256 createdCount = creatorCounts[creator];
        if (createdCount == 0) {
            return new uint256[](0);  // 返回空数组
        }
        
        uint256[] memory result = new uint256[](createdCount);
        uint256 resultIndex = 0;
        uint256 totalSupply = _tokenIdCounter.current() - 1;
        
        // 遍历所有tokenId查找该创建者的NFT
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (_exists(i) && qrDataMap[i].creator == creator) {
                result[resultIndex] = i;
                resultIndex++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 获取指定持有者的所有NFT
     * @param owner 持有者地址
     * @return 返回该持有者所有NFT的tokenId数组
     */
    function getTokensByOwner(address owner) 
        external 
        view 
        returns (uint256[] memory) 
    {
        require(owner != address(0), "QRCodeNFT: Invalid owner address");
        
        uint256 balance = balanceOf(owner);
        if (balance == 0) {
            return new uint256[](0);
        }
        
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }
        
        return result;
    }

    // ================================
    // 管理员函数 - 只有合约拥有者才能调用
    // ================================
    
    /**
     * @dev 设置铸造费用 - 管理员可以调整铸造价格
     * @param newFee 新的费用 (wei)
     */
    function setMintFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = mintFee;
        mintFee = newFee;
        emit MintFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev 设置最大供应量
     * @param newMaxSupply 新的最大供应量
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= _tokenIdCounter.current() - 1, "QRCodeNFT: New max supply too low");
        uint256 oldSupply = maxSupply;
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(oldSupply, newMaxSupply);
    }
    
    /**
     * @dev 设置单次最大铸造数量
     * @param newMaxMint 新的单次最大铸造数量
     */
    function setMaxMintPerTx(uint256 newMaxMint) external onlyOwner {
        require(newMaxMint > 0, "QRCodeNFT: Max mint must be greater than 0");
        maxMintPerTx = newMaxMint;
    }
    
    /**
     * @dev 设置内容最大长度
     * @param newMaxLength 新的内容最大长度
     */
    function setMaxContentLength(uint256 newMaxLength) external onlyOwner {
        require(newMaxLength > 0, "QRCodeNFT: Max length must be greater than 0");
        maxContentLength = newMaxLength;
    }
    
    /**
     * @dev 设置用户最大持有量
     * @param newMaxHolding 新的用户最大持有量
     */
    function setMaxHoldingPerUser(uint256 newMaxHolding) external onlyOwner {
        require(newMaxHolding > 0, "QRCodeNFT: Max holding must be greater than 0");
        maxHoldingPerUser = newMaxHolding;
    }
    
    /**
     * @dev 切换NFT激活状态 - NFT拥有者或管理员可以启用/禁用NFT
     * @param tokenId NFT ID
     */
    function toggleTokenStatus(uint256 tokenId) external validTokenId(tokenId) {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "QRCodeNFT: Not authorized to change status"
        );
        
        qrDataMap[tokenId].isActive = !qrDataMap[tokenId].isActive;
        emit QRNFTStatusChanged(tokenId, qrDataMap[tokenId].isActive);
    }
    
    /**
     * @dev 暂停合约 - 紧急情况下停止所有铸造功能
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev 恢复合约 - 重新启用所有功能
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev 提取合约中的所有以太币到拥有者地址
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "QRCodeNFT: No funds to withdraw");
        
        // 使用call方法转账，比transfer更安全
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "QRCodeNFT: Withdrawal failed");
        
        emit FundsWithdrawn(owner(), balance);
    }
    
    /**
     * @dev 紧急提取指定金额 - 管理员可以提取部分资金
     * @param amount 提取金额 (wei)
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "QRCodeNFT: Amount must be greater than 0");
        require(address(this).balance >= amount, "QRCodeNFT: Insufficient balance");
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "QRCodeNFT: Emergency withdrawal failed");
        
        emit FundsWithdrawn(owner(), amount);
    }

    // ================================
    // 查询统计函数 - 获取合约统计信息
    // ================================
    
    /**
     * @dev 获取当前已铸造的NFT总数
     * @return 当前供应量
     */
    function getCurrentSupply() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    
    /**
     * @dev 获取剩余可铸造数量
     * @return 剩余供应量
     */
    function getRemainingSupply() external view returns (uint256) {
        uint256 current = _tokenIdCounter.current() - 1;
        return current >= maxSupply ? 0 : maxSupply - current;
    }
    
    /**
     * @dev 检查指定内容是否已存在
     * @param content 要检查的内容
     * @return 是否存在
     */
    function isContentExists(string memory content) external view returns (bool) {
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        return contentHashToTokenId[contentHash] != 0;
    }
    
    /**
     * @dev 获取合约统计信息 - 一次性获取关键数据
     * @return totalSupply 当前总供应量
     * @return maxTotalSupply 最大供应量
     * @return currentMintFee 当前铸造费用
     * @return totalBalance 合约余额
     */
    function getContractStats() external view returns (
        uint256 totalSupply,
        uint256 maxTotalSupply,
        uint256 currentMintFee,
        uint256 totalBalance
    ) {
        return (
            _tokenIdCounter.current() - 1,
            maxSupply,
            mintFee,
            address(this).balance
        );
    }

    // ================================
    // 重写必要的函数 - 覆盖父合约的函数以实现自定义逻辑
    // ================================
    
    /**
     * @dev 在NFT转移前执行的钩子函数
     * 这个函数会在每次NFT转移前自动调用
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        // 更新用户持有量统计
        if (from != address(0)) {  // 不是铸造操作
            userHoldings[from]--;
        }
        if (to != address(0)) {    // 不是销毁操作
            userHoldings[to]++;
        }
    }
    
    /**
     * @dev 销毁NFT的内部函数
     * @param tokenId 要销毁的NFT ID
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        
        // 清除相关数据，释放存储空间
        delete qrDataMap[tokenId];
        
        // 清除内容哈希映射
        bytes32 contentHash = keccak256(abi.encodePacked(qrDataMap[tokenId].content));
        delete contentHashToTokenId[contentHash];
    }
    
    /**
     * @dev 获取NFT的元数据URI
     * 重写此函数以解决多重继承冲突
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @dev 检查合约支持的接口
     * 重写以解决多重继承冲突
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721, ERC721Enumerable, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    // ================================
    // 接收以太币函数 - 处理直接向合约发送以太币的情况
    // ================================
    
    /**
     * @dev 接收以太币的函数
     * 当有人直接向合约地址发送以太币时调用
     */
    receive() external payable {
        // 允许接收以太币，不执行任何操作
    }
    
    /**
     * @dev 后备函数
     * 当调用的函数不存在时调用
     */
    fallback() external payable {
        // 后备函数，通常用于处理未知的函数调用
    }
} 