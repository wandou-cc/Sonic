// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * ========================================
 * 第一步：基础合约结构
 * ========================================
 * 
 * 我们先从最简单的开始 - 创建一个基本的合约结构
 * 这里我们只导入最基础的ERC721，然后逐步添加功能
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title QRCodeNFT_Tutorial - 学习版本
 * @dev 这是一个用于学习的QRCodeNFT实现，我们会一步一步添加功能
 */
contract QRCodeNFT_Tutorial is ERC721 {
    
    /**
     * ========================================
     * 第二步：基本状态变量
     * ========================================
     * 
     * 状态变量是存储在区块链上的数据
     * 每次修改都会消耗gas费用，所以要合理设计
     */
    
    // 用于生成唯一tokenId的计数器
    uint256 private _tokenIdCounter;
    
    // 铸造费用 - 用户需要支付的以太币数量
    uint256 public mintFee = 0.01 ether;  // 0.01 ETH
    
    /**
     * ========================================
     * 第三步：构造函数
     * ========================================
     * 
     * 构造函数在合约部署时执行一次
     * 用于初始化合约的基本信息
     */
    constructor() ERC721("QR Code NFT Tutorial", "QRLEARN") {
        // 设置NFT集合的名称和符号
        // 名称: "QR Code NFT Tutorial" 
        // 符号: "QRLEARN"
        
        // tokenId从1开始，0通常表示"不存在"
        _tokenIdCounter = 1;
    }
    
    /**
     * ========================================
     * 第四步：基础铸造功能
     * ========================================
     * 
     * 这是最简单的铸造函数
     * 只需要支付费用就可以获得一个NFT
     */
    function simpleMint() external payable returns (uint256) {
        // 检查用户是否支付了足够的费用
        require(msg.value >= mintFee, "Insufficient payment");
        
        // 获取当前的tokenId
        uint256 tokenId = _tokenIdCounter;
        
        // 递增计数器，为下一次铸造准备
        _tokenIdCounter++;
        
        // 铸造NFT给调用者(msg.sender)
        _safeMint(msg.sender, tokenId);
        
        // 返回新铸造的tokenId
        return tokenId;
    }
    
    /**
     * ========================================
     * 第五步：添加QR码数据存储
     * ========================================
     * 
     * 现在我们为每个NFT添加QR码内容
     * 这是这个项目的核心功能
     */
    
    // 存储每个NFT的QR码数据
    struct QRData {
        string content;      // QR码的内容（比如网址）
        address creator;     // 创建者地址
        uint256 createdAt;   // 创建时间
    }
    
    // 映射：tokenId => QR数据
    mapping(uint256 => QRData) public qrDataMap;
    
    /**
     * 带QR码内容的铸造函数
     */
    function mintWithContent(string memory content) external payable returns (uint256) {
        // 检查支付
        require(msg.value >= mintFee, "Insufficient payment");
        
        // 检查内容不能为空
        require(bytes(content).length > 0, "Content cannot be empty");
        
        // 获取tokenId并递增
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        // 铸造NFT
        _safeMint(msg.sender, tokenId);
        
        // 存储QR数据
        qrDataMap[tokenId] = QRData({
            content: content,
            creator: msg.sender,
            createdAt: block.timestamp  // 当前区块时间
        });
        
        return tokenId;
    }
    
    /**
     * ========================================
     * 第六步：查询功能
     * ========================================
     * 
     * 添加一些函数来查询NFT信息
     * 这些是view函数，不会修改状态，也不消耗gas
     */
    
    /**
     * 获取NFT的QR码内容
     */
    function getContent(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return qrDataMap[tokenId].content;
    }
    
    /**
     * 获取NFT的完整信息
     */
    function getQRData(uint256 tokenId) external view returns (QRData memory) {
        require(_exists(tokenId), "Token does not exist");
        return qrDataMap[tokenId];
    }
    
    /**
     * 获取当前已铸造的NFT总数
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter - 1;  // 减1因为我们从1开始计数
    }
    
    /**
     * ========================================
     * 第七步：事件 - 记录重要操作
     * ========================================
     * 
     * 事件可以让外部应用监听合约的状态变化
     * 比如前端可以监听铸造事件来更新界面
     */
    
    event QRNFTMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string content
    );
    
    /**
     * 改进的铸造函数 - 添加事件
     */
    function mintWithEvent(string memory content) external payable returns (uint256) {
        require(msg.value >= mintFee, "Insufficient payment");
        require(bytes(content).length > 0, "Content cannot be empty");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(msg.sender, tokenId);
        
        qrDataMap[tokenId] = QRData({
            content: content,
            creator: msg.sender,
            createdAt: block.timestamp
        });
        
        // 发出事件，通知外部应用
        emit QRNFTMinted(tokenId, msg.sender, content);
        
        return tokenId;
    }
    
    /**
     * ========================================
     * 第八步：添加安全性 - 拥有者权限
     * ========================================
     * 
     * 现在我们添加一些管理员功能
     * 首先需要导入Ownable合约
     */
    
    // 注意：这里我们需要添加拥有者变量和修饰符
    // 在实际项目中，我们会导入OpenZeppelin的Ownable合约
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 在构造函数中设置拥有者
    // 注意：这个应该添加到上面的构造函数中
    // 这里只是为了展示概念
    function initOwner() external {
        require(owner == address(0), "Owner already set");
        owner = msg.sender;
    }
    
    /**
     * 修改铸造费用 - 只有拥有者可以调用
     */
    function setMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
    }
    
    /**
     * 提取合约中的以太币 - 只有拥有者可以调用
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        // 转账给拥有者
        payable(owner).transfer(balance);
    }
    
    /**
     * ========================================
     * 第九步：防重复内容
     * ========================================
     * 
     * 防止用户铸造相同内容的NFT
     */
    
    // 映射：内容哈希 => tokenId
    mapping(bytes32 => uint256) public contentHashToTokenId;
    
    /**
     * 检查内容是否已存在
     */
    function isContentExists(string memory content) public view returns (bool) {
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        return contentHashToTokenId[contentHash] != 0;
    }
    
    /**
     * 防重复的铸造函数
     */
    function mintUnique(string memory content) external payable returns (uint256) {
        require(msg.value >= mintFee, "Insufficient payment");
        require(bytes(content).length > 0, "Content cannot be empty");
        
        // 检查内容是否已存在
        require(!isContentExists(content), "Content already exists");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(msg.sender, tokenId);
        
        qrDataMap[tokenId] = QRData({
            content: content,
            creator: msg.sender,
            createdAt: block.timestamp
        });
        
        // 记录内容哈希
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        contentHashToTokenId[contentHash] = tokenId;
        
        emit QRNFTMinted(tokenId, msg.sender, content);
        
        return tokenId;
    }
    
    /**
     * ========================================
     * 学习总结
     * ========================================
     * 
     * 通过这个教程，我们学会了：
     * 
     * 1. 基本合约结构 - 继承ERC721
     * 2. 状态变量 - 存储数据在区块链上
     * 3. 构造函数 - 初始化合约
     * 4. 基础铸造 - 创建NFT的核心功能
     * 5. 数据存储 - 使用struct和mapping
     * 6. 查询功能 - view函数获取信息
     * 7. 事件系统 - 记录和通知状态变化
     * 8. 权限控制 - 保护敏感操作
     * 9. 业务逻辑 - 防重复等特殊需求
     * 
     * 下一步可以学习：
     * - 暂停功能 (Pausable)
     * - 防重入攻击 (ReentrancyGuard)
     * - 批量操作
     * - Gas优化技巧
     * - 更复杂的权限管理
     */
} 