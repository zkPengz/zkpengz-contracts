// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './erc721a/contracts/ERC721A.sol';
import './erc721a/contracts/extensions/ERC721AQueryable.sol';
import './erc721a/contracts/extensions/ERC721ABurnable.sol';
import './erc721a/contracts/extensions/ERC4906A.sol';
import './erc721a/contracts/extensions/ERC4907A.sol';
import './MultisigOwnable.sol';
import './BaseHelper.sol';

contract ZKPENGZ is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    ERC4906A,
    ERC4907A,
    MultisigOwnable
{
    using BaseHelper for uint;

    uint256 public immutable maxSupply;
    uint256 public maxPerWalletPublic;
    uint256 public maxPerWalletWl;
    uint256 public maxPerTx;
    uint256 public price;

    string public baseURI;
    string public colors;
    uint16[][6] TIERS;
    uint seedNonce = 0;

    bool public saleStatePublic;    // 0:close | 1:open
    bool public saleStateWl;    // 0:close | 1:open
    bool public mintFrozen;    //    0:not frozen | 1:frozen

    bytes32 public merkleRootWl;
    mapping(address => uint256) public mintedByWalletPublic;
    mapping(address => uint256) public mintedByWalletWl;

    mapping(uint => Layer[]) public layerTypes;
    mapping(uint => bool) internal hashToMinted;
    mapping(uint => uint) internal tokenIdToHash;

    event NewHash(uint hash);
    event BoolVal(bool state);
    event MintedHash(uint mintIndex, uint hash);

    error InternalError();
    error CantGenerateGen();
    error CantGenerateDna();
    error CallByContractNotAllowed();
    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerWalletReached();
    error MaxPerTxReached();
    error IncorrectValueSent();
    error MismatchingLengths();
    error MintFrozenForever();
    error WithdrawlError();
    error IncorrectMerkleProof();

    // Layer struct
    // - layerName used in metadata
    // - pixels contains layer data
    struct Layer {
            string layerName;
            string pixels;
    }

    // string arrays
    string[] LETTERS = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H"
    ];

    // names of layers
    string[] NAMES = [
    "Background",
    "Body",
    "OnBody",
    "OnHead",
    "Beak",
    "Eyes"
    ];

    constructor(
        uint256 _maxSupply,
        uint256 _maxPerWalletPublic,
        uint256 _maxPerWalletWl,
        uint256 _maxPerTx,
        uint256 _price,
        string memory initialName,
        string memory initialSymbol
    ) ERC721A(initialName, initialSymbol) {
        maxSupply = _maxSupply;
        maxPerWalletPublic = _maxPerWalletPublic;
        maxPerWalletWl = _maxPerWalletWl;
        maxPerTx = _maxPerTx;
        price = _price;
        _nameOverride = initialName;
        _symbolOverride = initialSymbol;

        // Declare all the rarity tiers
        // -----
        // 0_Background
        TIERS[0] = [2889, 222, 222];
        // 1_Body
        TIERS[1] = [400, 3, 1900, 300, 150, 30, 300, 100, 50, 100];
        // 2_On_Body
        TIERS[2] = [55, 100, 100, 100, 120, 100, 120, 100, 25, 25, 25, 25, 25, 25, 25, 25, 25, 45, 75, 75, 75, 50, 555, 45, 45, 45, 45, 50, 50, 50, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 75, 70, 70, 48, 50, 50, 50, 50, 45];
        // 3_On_Head
        TIERS[3] = [55, 55, 33, 18, 18, 18, 18, 18, 18, 18, 18, 9, 18, 18, 18, 18, 35, 32, 55, 35, 26, 18, 18, 18, 18, 18, 18, 18, 18, 10, 18, 18, 18, 18, 35, 35, 35, 25, 35, 25, 35, 35, 45, 35, 20, 18, 20, 18, 20, 20, 20, 20, 20, 10, 18, 18, 20, 18, 40, 25, 35, 25, 25, 25, 25, 35, 35, 35, 35, 35, 35, 30, 30, 30, 30, 35, 35, 35, 20, 20, 20, 20, 20, 20, 20, 20, 20, 360, 30, 30, 35, 35, 23, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 15, 15, 15, 15, 15, 15, 15, 15, 10, 15, 15, 15, 33, 35];
        // 4_Beak
        TIERS[4] = [150, 200, 200, 303, 400, 600, 150, 30, 600, 700];
        // 5_Eyes
        TIERS[5] = [93, 75, 125, 50, 50, 50, 50, 50, 50, 50, 40, 50, 100, 250, 110, 110, 230, 130, 230, 200, 225, 150, 100, 80, 80, 35, 100, 100, 30, 35, 35, 75, 75, 50, 70];
        // -----

    }

    // =============================================================
    //                                                    MINTS
    // =============================================================

    function mintPublic(uint256 quantity) external payable {
        if (tx.origin != msg.sender) revert CallByContractNotAllowed();
        if (mintFrozen) revert MintFrozenForever();
        if (!saleStatePublic) revert SaleNotActive();
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();
        if (mintedByWalletPublic[msg.sender] + quantity > maxPerWalletPublic) revert MaxPerWalletReached();
        if (quantity > maxPerTx) revert MaxPerTxReached();
        if (msg.value != price * quantity) revert IncorrectValueSent();

        mintedByWalletPublic[msg.sender] += quantity;
        _generateDna(quantity);
        _mint(msg.sender, quantity);
    }

    function mintWl(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        if (tx.origin != msg.sender) revert CallByContractNotAllowed();
        if (mintFrozen) revert MintFrozenForever();
        if (!saleStateWl) revert SaleNotActive();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        if (!MerkleProof.verify(merkleProof, merkleRootWl, leaf)) revert IncorrectMerkleProof();

        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();
        if (mintedByWalletWl[msg.sender] + quantity > maxPerWalletWl) revert MaxPerWalletReached();
        if (msg.value != price * quantity) revert IncorrectValueSent();

        mintedByWalletWl[msg.sender] += quantity;
        _generateDna(quantity);
        _mint(msg.sender, quantity);
    }

    /* Mint to many addresses in a single tx by dev wallet */

    function devMint(address[] calldata addresses, uint256[] calldata amount) external onlyOwner {
        if (mintFrozen) revert MintFrozenForever();
        if (addresses.length != amount.length) revert MismatchingLengths();

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amount.length; i++) {
                totalAmount += amount[i];
        }

        for (uint256 i; i < addresses.length; i++) {
            if (_totalMinted() + totalAmount > maxSupply) revert MaxSupplyReached();
            _generateDna(amount[i]);
            _safeMint(addresses[i], amount[i]);
        }

    }

    // =============================================================
    //                                                    OVERRIDES
    // =============================================================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    string private _nameOverride;
    string private _symbolOverride;

    function name() public view override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(_nameOverride).length == 0) {
            return ERC721A.name();
        }
        return _nameOverride;
    }

    function symbol() public view override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(_symbolOverride).length == 0) {
            return ERC721A.symbol();
        }
        return _symbolOverride;
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
            public
            view
            virtual
            override(ERC721A, IERC721A, ERC4906A, ERC4907A)
            returns (bool)
    {
            // Supports the following interfaceIds:
            // - IERC165: 0x01ffc9a7
            // - IERC721: 0x80ac58cd
            // - IERC721Metadata: 0x5b5e139f
            // - IERC2981: 0x2a55205a
            // - IERC4907: 0xad092b5c
            // - IERC4906: 0x49064906
            return
                    ERC721A.supportsInterface(interfaceId) ||
                    ERC4906A.supportsInterface(interfaceId) ||
                    ERC4907A.supportsInterface(interfaceId);
    }

    // =============================================================
    //                                         OWNERSHIPS OPERATIONS
    // =============================================================

    uint256 constant private MAX_INT_TYPE = type(uint256).max;

    function setSaleStatePublic(bool newSaleState) external onlyRealOwner {
        saleStatePublic = newSaleState;
        emit BoolVal(saleStatePublic);
    }

    function setSaleStateWl(bool newSaleState) external onlyRealOwner {
        saleStateWl = newSaleState;
        emit BoolVal(saleStateWl);
    }

    function setMaxPerWalletPublic(uint256 newMaxPerWalletPublic) external onlyOwner {
        maxPerWalletPublic = newMaxPerWalletPublic;
    }

    function setMaxPerWalletWl(uint256 newMaxPerWalletWl) external onlyOwner {
        maxPerWalletWl = newMaxPerWalletWl;
    }

    function setMerkleRootWl(bytes32 _merkleRoot) external onlyOwner {
            merkleRootWl = _merkleRoot;
    }

    function setSalePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdraw() external onlyRealOwner {
            (bool success, ) = msg.sender.call {value: address(this).balance}("");
            if(!success) revert WithdrawlError();
    }

    function setNameAndSymbol(string calldata _newName, string calldata _newSymbol) external onlyRealOwner {
        _nameOverride = _newName;
        _symbolOverride = _newSymbol;
    }

    /**
     *    @notice CAUTION: mint will be frozen forever when executed!
     */
    function freezMint() external onlyRealOwner {
        mintFrozen = true; // Mint frozen forever
        emit BoolVal(mintFrozen);
    }

    // =============================================================
    //                                         PUBLIC VIEWS
    // =============================================================

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    // =============================================================
    //                          RENDER
    // =============================================================

    // ------------------------- Methods for mint and related functions -------------------------

    /* Converts a digit from 0 - 3333 into its corresponding rarity based on the given rarity tier. */
    function _rarityGen(uint _randInput, uint _rarityTier, bool _custom, uint16[32] memory _tiers)
    internal
    view
    returns (uint)
    {
        uint16 currentLowerBound = 0;
        uint16[] memory tiers = TIERS[_rarityTier];
        if (_custom) {
            for (uint a = 0; a < tiers.length; a++) {
                tiers[a] = _tiers[a];
            }
        }
        for (uint i = 0; i < tiers.length; i++) {
            uint16 thisPercentage = tiers[i];
            if (thisPercentage == 0) continue;
            if (
                _randInput >= currentLowerBound &&
                _randInput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert CantGenerateGen();
    }

    /* Return changed hash, taking into account the dependence of layers */
    function _establishDeps(uint256[] memory hash)
    internal
    pure
    returns (uint256[] memory)
    {
        //  "Jon_Snow": ["2_On_Body", "3_On_Head"],
        //  "Skeleton": ["2_On_Body"],
        //  "Black_Tail": ["2_On_Body"],
        //  "Zombie": ["2_On_Body"],
        //  "Rainbow": ["2_On_Body"],
        if (hash[1] == 5 || hash[1] == 1 || hash[1] >= 7) {
            hash[2] = 22; // NONE#555.png
        }
        if (hash[1] == 5) {
            hash[3] = 87; // NONE#360.png
        }

        return hash;
    }

    /* Generates a hash from a tokenId, address, and random number. */
    function _genHash(
        uint _t,
        address _a,
        uint _c
    )
    internal
    returns (uint)
    {
        if (_c >= 20) revert CantGenerateDna();

        uint16[32] memory tiers;
        bool custom;
        uint maxRand;
        uint[] memory currentHash = new uint[](6);

        for (uint i = 0; i <= 5; i++) {
            seedNonce++;
            custom = false;
            maxRand = 3333;

            // custom tiers can be here
            uint _randInput = uint(BaseHelper.strongRandom(_t, _a, _c, seedNonce) % maxRand);
            uint gen = _rarityGen(_randInput, i, custom, tiers);
            currentHash[i] = gen;
        }
        currentHash = _establishDeps(currentHash);

        uint packedWithoutBg = _encodeHashWithoutBg(currentHash);
        if (hashToMinted[packedWithoutBg]) return _genHash(_t, _a, _c + 1);
        hashToMinted[packedWithoutBg] = true;

        return _encodeHash(currentHash);
    }

    /* Helper function to reduce pixel size within contract */
    function _letterToNumber(string memory _letter)
    internal
    view
    returns (uint)
    {
        for (uint i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_letter)))
            ) return i;
        }
        revert InternalError();
    }

    /* Function that allow mint random nft */
    function _generateDna(uint256 quantity)
    internal
    {
        uint startIndex = _nextTokenId();
        for (uint i = 0; i < quantity; i++) {
            uint mintIndex = startIndex + i;
            tokenIdToHash[mintIndex] = _genHash(mintIndex, msg.sender, 0);
            emit MintedHash(mintIndex, tokenIdToHash[mintIndex]);
        }
    }

    // ------------------------- Overridden tokenURI and related functions -------------------------

    /* Return hash by token id */
    function getTokenHash(uint _tokenId)
    public
    view
    onlyOwner
    returns (string memory)
    {
        uint256[] memory _decodedHash = _decodeHash(tokenIdToHash[_tokenId]);
        return string(abi.encodePacked(
            "Background: ", _decodedHash[0], ", ",
            "Body: ", _decodedHash[1], ", ",
            "Eyes: ", _decodedHash[2], ", ",
            "Head: ", _decodedHash[3], ", ",
            "Clothing: ", _decodedHash[4], ", ",
            "Accessories: ", _decodedHash[5]
        ));
    }

    /* Returns svg image of token by hash */
    function _hashToSVG(uint _hash)
    internal
    view
    returns (string memory)
    {
        string memory svgString;
        uint256[] memory _decodedHash = _decodeHash(_hash);

        for (uint i = 0; i <= 5; i++) {
            uint step = 6;
            uint thisLayerIndex = _decodedHash[i];

            Layer[] memory layerArr = layerTypes[i];
            Layer memory layer = layerArr[thisLayerIndex];

            for (
                uint j = 0;
                j < uint(bytes(layer.pixels).length / step);
                j++
            ) {
                string memory thisPixel = BaseHelper.substring(
                    layer.pixels,
                    j * step,
                    j * step + step
                );

                uint x = _letterToNumber(
                    BaseHelper.substring(thisPixel, 0, 1)
                );
                uint y = _letterToNumber(
                    BaseHelper.substring(thisPixel, 1, 2)
                );
                uint w = _letterToNumber(
                    BaseHelper.substring(thisPixel, 2, 3)
                );
                string memory color = BaseHelper.substring(thisPixel, 3, 6);

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        color,
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "' width='",
                        w.toString(),
                        "'/>"
                    )
                );
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="pix-pin-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 16 16"> ',
                    svgString,
                    '<style>rect{height:1px;} #pix-pin-svg{shape-rendering: crispedges;} ',
                    colors,
                    '</style></svg>'
            )
        );

        return svgString;
    }

    /* Returns metadata of token by hash */
    function _hashToMetadata(uint _hash)
    internal
    view
    returns (string memory)
    {
        string memory metadataString;
        uint256[] memory _decodedHash = _decodeHash(_hash);

        for (uint i = 0; i <= 5; i++) {
            uint thisLayerIndex = _decodedHash[i];

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"layer_type":"',
                    NAMES[i],
                    '","value":"',
                    layerTypes[i][thisLayerIndex].layerName,
                    '"}'
                )
            );

            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /* Overridden function for getting token uri */
    function tokenURI(uint _tokenId)
    public
    view
    override (ERC721A, IERC721A)
    returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        uint tokenHash = tokenIdToHash[_tokenId];

        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                BaseHelper.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Pengz #',
                                BaseHelper.toString(_tokenId),
                                '", "description": "Pengz is a collection of 3,333 unique penguins. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just blockchain.", "image": "data:image/svg+xml;base64,',
                                BaseHelper.encode(
                                    bytes(_hashToSVG(tokenHash))
                                ),
                                '","attributes":',
                                _hashToMetadata(tokenHash),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function _encodeHash(uint256[] memory _hash)
    internal
    pure
    returns(uint256 _encoded)
    {
        _encoded |= uint256(uint32(_hash[0])) << 160;
        _encoded |= uint256(uint32(_hash[1])) << 128;
        _encoded |= uint256(uint32(_hash[2])) << 96;
        _encoded |= uint256(uint32(_hash[3])) << 64;
        _encoded |= uint256(uint32(_hash[4])) << 32;
        _encoded |= uint256(uint32(_hash[5]));

        return _encoded;
    }

    function _encodeHashWithoutBg(uint256[] memory _hash)
    internal
    pure
    returns(uint256 _encoded)
    {
        _encoded |= uint256(uint32(_hash[1])) << 128;
        _encoded |= uint256(uint32(_hash[2])) << 96;
        _encoded |= uint256(uint32(_hash[3])) << 64;
        _encoded |= uint256(uint32(_hash[4])) << 32;
        _encoded |= uint256(uint32(_hash[5]));

        return _encoded;
    }

    function _decodeHash(uint256 _encoded)
    internal
    pure
    returns (uint256[] memory)
    {
        uint256[] memory _hash = new uint[](6);
        _hash[0] = uint256(uint32(_encoded >> 160));
        _hash[1] = uint256(uint32(_encoded >> 128));
        _hash[2] = uint256(uint32(_encoded >> 96));
        _hash[3] = uint256(uint32(_encoded >> 64));
        _hash[4] = uint256(uint32(_encoded >> 32));
        _hash[5] = uint256(uint32(_encoded));

        return _hash;
    }

    // ------------------------- Methods for layers management -------------------------

    function setColors(string memory _colors)
    public
    onlyOwner
    {
        colors = _colors;
    }

    /* Clear all layers */
    function clearLayers()
    public
    onlyOwner
    {
        for (uint i = 0; i <= 5; i++) {
            delete layerTypes[i];
        }
    }

    /* Clear layer */
    function clearLayer(uint _index)
    public
    onlyOwner
    {
        delete layerTypes[_index];
    }

    /* Add custom tiers */
    function addTiers(uint _index, uint16[] memory _tiers)
    public
    onlyOwner
    {
        TIERS[_index] = _tiers;

        return;
    }

    /* Add layers of the same type */
    function addLayerType(uint _index, Layer[] memory _layers)
    public
    onlyOwner
    {
        for (uint i = 0; i < _layers.length; i++) {
            layerTypes[_index].push(
                Layer(
                    _layers[i].layerName,
                    _layers[i].pixels
                )
            );
        }

        return;
    }

    // ------------------------- Methods for basic contract management -------------------------

    /* Generate new hash */
    function generateHash()
    public
    onlyOwner
    {
        uint h = _genHash(0, msg.sender, 0);
        emit NewHash(h);
    }
}