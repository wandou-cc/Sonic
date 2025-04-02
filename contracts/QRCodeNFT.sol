// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title QRCodeNFT
 * @dev 二维码NFT合约 - 用户可以铸造包含自定义内容的二维码NFT
 * @author QR-NFT Team
 */
contract QRCodeNFT is 
    ERC721, 
    ERC721URIStorage, 
    ERC721Enumerable, 
    Pausable, 
    Ownable, 
    ReentrancyGuard 
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ================================
    // 状态变量
    // ================================
    
    Counters.Counter private _tokenIdCounter;
    
    // 铸造费用 (wei)
    uint256 public mintFee = 0.01 ether;
    
    // 最大供应量
    uint256 public maxSupply = 1000000;
    
    // 单次最大铸造数量
    uint256 public maxMintPerTx = 10;
    
    // 内容最大长度限制
    uint256 public maxContentLength = 1000;
    
    // 每个用户最大持有量
    uint256 public maxHoldingPerUser = 100;

    // ================================
    // 数据结构
    // ================================
    
    struct QRData {
        string content;          // 二维码原始内容
        string title;           // NFT标题
        string description;     // NFT描述
        address creator;        // 创建者地址
        uint256 createdAt;      // 创建时间
        uint256 views;          // 查看次数
        bool isActive;          // 是否激活状态
    }
    
    // tokenId => QRData
    mapping(uint256 => QRData) public qrDataMap;
    
    // 用户地址 => 持有数量
    mapping(address => uint256) public userHoldings;
    
    // 创建者地址 => 创建的NFT数量
    mapping(address => uint256) public creatorCounts;
    
    // 内容哈希 => tokenId (防止重复内容)
    mapping(bytes32 => uint256) public contentHashToTokenId;

    // ================================
    // 事件定义
    // ================================
    
    event QRNFTMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string content,
        string title,
        string metadataURI
    );
    
    event QRNFTViewed(
        uint256 indexed tokenId,
        address indexed viewer,
        uint256 viewCount
    );
    
    event QRNFTStatusChanged(
        uint256 indexed tokenId,
        bool isActive
    );
    
    event MintFeeUpdated(uint256 oldFee, uint256 newFee);
    event MaxSupplyUpdated(uint256 oldSupply, uint256 newSupply);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // ================================
    // 修饰符
    // ================================
    
    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "QRCodeNFT: Token does not exist");
        _;
    }
    
    modifier validContent(string memory content) {
        require(bytes(content).length > 0, "QRCodeNFT: Content cannot be empty");
        require(bytes(content).length <= maxContentLength, "QRCodeNFT: Content too long");
        _;
    }
    
    modifier validMintAmount(uint256 amount) {
        require(amount > 0, "QRCodeNFT: Amount must be greater than 0");
        require(amount <= maxMintPerTx, "QRCodeNFT: Exceeds max mint per transaction");
        _;
    }
    
    modifier checkSupply(uint256 amount) {
        require(_tokenIdCounter.current() + amount <= maxSupply, "QRCodeNFT: Exceeds max supply");
        _;
    }
    
    modifier checkUserHolding(address user, uint256 amount) {
        require(userHoldings[user] + amount <= maxHoldingPerUser, "QRCodeNFT: Exceeds max holding per user");
        _;
    }

    // ================================
    // 构造函数
    // ================================
    
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        // tokenId从1开始
        _tokenIdCounter.increment();
    }

    // ================================
    // 核心功能函数
    // ================================
    
    /**
     * @dev 铸造单个QR NFT
     * @param content 二维码内容
     * @param title NFT标题
     * @param description NFT描述
     * @param metadataURI IPFS元数据URI
     */
    function mint(
        string memory content,
        string memory title,
        string memory description,
        string memory metadataURI
    ) 
        external 
        payable 
        whenNotPaused
        nonReentrant
        validContent(content)
        checkSupply(1)
        checkUserHolding(msg.sender, 1)
        returns (uint256) 
    {
        require(msg.value >= mintFee, "QRCodeNFT: Insufficient payment");
        require(bytes(title).length > 0, "QRCodeNFT: Title cannot be empty");
        require(bytes(metadataURI).length > 0, "QRCodeNFT: Metadata URI cannot be empty");
        
        // 检查内容是否已存在
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        require(contentHashToTokenId[contentHash] == 0, "QRCodeNFT: Content already exists");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // 铸造NFT
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);
        
        // 存储QR数据
        qrDataMap[tokenId] = QRData({
            content: content,
            title: title,
            description: description,
            creator: msg.sender,
            createdAt: block.timestamp,
            views: 0,
            isActive: true
        });
        
        // 更新映射
        contentHashToTokenId[contentHash] = tokenId;
        userHoldings[msg.sender]++;
        creatorCounts[msg.sender]++;
        
        emit QRNFTMinted(tokenId, msg.sender, content, title, metadataURI);
        
        return tokenId;
    }
    
    /**
     * @dev 批量铸造QR NFT
     * @param contents 二维码内容数组
     * @param titles NFT标题数组
     * @param descriptions NFT描述数组
     * @param metadataURIs IPFS元数据URI数组
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
        require(contents.length == titles.length, "QRCodeNFT: Arrays length mismatch");
        require(contents.length == descriptions.length, "QRCodeNFT: Arrays length mismatch");
        require(contents.length == metadataURIs.length, "QRCodeNFT: Arrays length mismatch");
        require(msg.value >= mintFee * contents.length, "QRCodeNFT: Insufficient payment");
        
        uint256[] memory tokenIds = new uint256[](contents.length);
        
        for (uint256 i = 0; i < contents.length; i++) {
            require(bytes(contents[i]).length > 0, "QRCodeNFT: Content cannot be empty");
            require(bytes(contents[i]).length <= maxContentLength, "QRCodeNFT: Content too long");
            require(bytes(titles[i]).length > 0, "QRCodeNFT: Title cannot be empty");
            require(bytes(metadataURIs[i]).length > 0, "QRCodeNFT: Metadata URI cannot be empty");
            
            // 检查内容是否已存在
            bytes32 contentHash = keccak256(abi.encodePacked(contents[i]));
            require(contentHashToTokenId[contentHash] == 0, "QRCodeNFT: Duplicate content found");
            
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, metadataURIs[i]);
            
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
            
            emit QRNFTMinted(tokenId, msg.sender, contents[i], titles[i], metadataURIs[i]);
        }
        
        userHoldings[msg.sender] += contents.length;
        creatorCounts[msg.sender] += contents.length;
        
        return tokenIds;
    }

    // ================================
    // 查看和查询函数
    // ================================
    
    /**
     * @dev 获取NFT的二维码内容
     * @param tokenId NFT ID
     */
    function getContent(uint256 tokenId) 
        external 
        validTokenId(tokenId) 
        returns (string memory) 
    {
        qrDataMap[tokenId].views++;
        emit QRNFTViewed(tokenId, msg.sender, qrDataMap[tokenId].views);
        return qrDataMap[tokenId].content;
    }
    
    /**
     * @dev 获取NFT的完整数据 (只读，不增加查看次数)
     * @param tokenId NFT ID
     */
    function getQRData(uint256 tokenId) 
        external 
        view 
        validTokenId(tokenId) 
        returns (QRData memory) 
    {
        return qrDataMap[tokenId];
    }
    
    /**
     * @dev 获取用户创建的所有NFT
     * @param creator 创建者地址
     */
    function getTokensByCreator(address creator) 
        external 
        view 
        returns (uint256[] memory) 
    {
        require(creator != address(0), "QRCodeNFT: Invalid creator address");
        
        uint256 createdCount = creatorCounts[creator];
        if (createdCount == 0) {
            return new uint256[](0);
        }
        
        uint256[] memory result = new uint256[](createdCount);
        uint256 resultIndex = 0;
        uint256 totalSupply = _tokenIdCounter.current() - 1;
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (_exists(i) && qrDataMap[i].creator == creator) {
                result[resultIndex] = i;
                resultIndex++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 获取用户持有的所有NFT
     * @param owner 持有者地址
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
    // 管理员函数
    // ================================
    
    /**
     * @dev 设置铸造费用
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
     * @dev 切换NFT激活状态
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
     * @dev 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev 提取合约余额
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "QRCodeNFT: No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "QRCodeNFT: Withdrawal failed");
        
        emit FundsWithdrawn(owner(), balance);
    }
    
    /**
     * @dev 紧急提取指定金额
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
    // 查询统计函数
    // ================================
    
    /**
     * @dev 获取当前总供应量
     */
    function getCurrentSupply() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    
    /**
     * @dev 获取剩余可铸造数量
     */
    function getRemainingSupply() external view returns (uint256) {
        uint256 current = _tokenIdCounter.current() - 1;
        return current >= maxSupply ? 0 : maxSupply - current;
    }
    
    /**
     * @dev 检查内容是否已存在
     * @param content 要检查的内容
     */
    function isContentExists(string memory content) external view returns (bool) {
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        return contentHashToTokenId[contentHash] != 0;
    }
    
    /**
     * @dev 获取合约统计信息
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
    // 重写必要的函数
    // ================================
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        // 更新用户持有量
        if (from != address(0)) {
            userHoldings[from]--;
        }
        if (to != address(0)) {
            userHoldings[to]++;
        }
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        
        // 清除数据
        delete qrDataMap[tokenId];
        
        // 清除内容哈希映射
        bytes32 contentHash = keccak256(abi.encodePacked(qrDataMap[tokenId].content));
        delete contentHashToTokenId[contentHash];
    }
    
    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721, ERC721Enumerable, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    // ================================
    // 接收以太币函数
    // ================================
    
    receive() external payable {
        // 允许接收以太币
    }
    
    fallback() external payable {
        // 后备函数
    }
} 