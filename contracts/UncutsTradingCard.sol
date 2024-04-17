// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract UncutsTradingCard is ERC1155, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    string public name = "TradingCard";
    string public symbol = "TC";

    error TradingCard__Unauthorized(bytes32 reason, address caller);
    error TradingCard__PublicReleaseDisabled();
    error TradingCard__CardNotReleased();

    error TradingCard__ContractIsPaused();
    error TradingCard__EpochNotEnded();
    error TradingCard_OnlyAdmin();

    //private vars
    uint256 private _tokenIdCount = 0;
    mapping(uint256 => address) private _tokenAuthors;
    mapping(uint256 => uint256) private _totalSupply;

    uint256 private MIN_HOLDING_TIME = 60;
    mapping(address holder => uint256 blockTimestamp) internal purchaseTime;

    uint128 private BASE_PRICE_POINTS = 1000;

    address private _admin = msg.sender;

    string _metadataBaseUrlPrefix = "";
    string _metadataBaseUrlSuffix = "";
    string _contractMetadataUrl = "";

    //public vars
    uint256 public protocolReleaseCardFee = 0.005 ether; //absolute amount of eth required to mint first card

    uint32 public protocolTradeCardFeePercent = 2500;
    uint32 public prizePoolTradeCardFeePercent = 2500;
    uint32 public authorTradeCardFeePercent = 5000;

    bool public publicReleaseEnabled = false;
    address public protocolFeeDestination = msg.sender;
    address public prizePoolFeeDestination = msg.sender;

    bool public isPaused = false;

    uint256 public epoch = 1;

    IERC20 public payToken;

    uint256 public epochFinish = block.timestamp + EPOCH_DURATION;

    uint256 public constant EPOCH_DURATION = 7 days;

    //events
    event Release(address author, uint256 tokenId, uint256 amount);

    event Buy(
        address payer,
        address holder,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 authorFee,
        uint256 totalSupply
    );

    event Sell(
        address payer,
        address holder,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 authorFee,
        uint256 totalSupply
    );

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    event ToggledPause(bool oldPauseState, bool newPauseState, address caller);

    event EpochAdvanced(uint256 newEpoch);

    /// @notice Ensures that the contract is not in a paused state.
    modifier whenNotPaused() {
        if (isPaused) revert TradingCard__ContractIsPaused();
        _;
    }

    /// @notice Ensures that the contract is not in a paused state.
    modifier whenPublicReleaseEnabled() {
        if (!publicReleaseEnabled) revert TradingCard__PublicReleaseDisabled();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert TradingCard_OnlyAdmin();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory metadataBaseUrlPrefix,
        string memory metadataBaseUrlSuffix,
        IERC20 _payToken,
        uint128 _BASE_PRICE_POINTS
    ) Ownable(msg.sender) ERC1155("") {
        name = _name;
        symbol = _symbol;
        _metadataBaseUrlPrefix = metadataBaseUrlPrefix;
        _metadataBaseUrlSuffix = metadataBaseUrlSuffix;
        payToken = _payToken;
        BASE_PRICE_POINTS = _BASE_PRICE_POINTS;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        // Tokens minted above the supply cap will not have associated metadata.
        require(
            _totalSupply[tokenId] > 0,
            "ERC1155Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    _metadataBaseUrlPrefix,
                    Strings.toString(tokenId),
                    _metadataBaseUrlSuffix,
                    Strings.toString(epoch)
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataUrl;
    }

    function setProtocolReleaseCardFee(uint256 newValue) public onlyOwner {
        protocolReleaseCardFee = newValue;
    }

    function setProtocolTradeCardFeePercent(uint32 newValue) public onlyOwner {
        require(newValue <= 100000, "Value must be between 0 and 100000");
        protocolTradeCardFeePercent = newValue;
    }

    function setPrizePoolTradeCardFeePercent(uint32 newValue) public onlyOwner {
        require(newValue <= 100000, "Value must be between 0 and 100000");
        prizePoolTradeCardFeePercent = newValue;
    }

    function setAuthorTradeCardFeePercent(uint32 newValue) public onlyOwner {
        require(newValue <= 100000, "Value must be between 0 and 100000");
        authorTradeCardFeePercent = newValue;
    }

    function setProtocolFeeDestination(
        address newAddress
    ) public onlyOwner returns (address) {
        require(newAddress != address(0), "Invalid address");
        protocolFeeDestination = newAddress;
        return protocolFeeDestination;
    }

    function setPrizePoolFeeDestination(
        address newAddress
    ) public onlyOwner returns (address) {
        require(newAddress != address(0), "Invalid address");
        prizePoolFeeDestination = newAddress;
        return prizePoolFeeDestination;
    }

    function setAdmin(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Invalid address");
        _admin = newAddress;
    }

    function setPublicReleaseStatus(bool newValue) public onlyOwner {
        publicReleaseEnabled = newValue;
    }

    function advanceEpoch() public returns (uint256) {
        uint256 timestamp = block.timestamp;

        if (timestamp >= epochFinish) {
            epoch += 1;
            epochFinish = epochFinish + EPOCH_DURATION;
        } else {
            revert TradingCard__EpochNotEnded();
        }

        emit BatchMetadataUpdate(0, _tokenIdCount);

        emit EpochAdvanced(epoch);

        return epoch;
    }

    function setMetadataBaseUrlPrefix(string memory newValue) public onlyOwner {
        _metadataBaseUrlPrefix = newValue;
        emit BatchMetadataUpdate(0, _tokenIdCount);
    }

    function setMetadataBaseUrlSuffix(string memory newValue) public onlyOwner {
        _metadataBaseUrlSuffix = newValue;
        emit BatchMetadataUpdate(0, _tokenIdCount);
    }

    function setContractMetadataUrl(string memory newValue) public onlyOwner {
        _contractMetadataUrl = newValue;
    }

    function setMinHoldingTime(uint256 newValue) public onlyOwner {
        MIN_HOLDING_TIME = newValue;
    }

    function setPause(bool state) public onlyOwner {
        emit ToggledPause(isPaused, state, msg.sender);
        isPaused = state;
    }

    function _releaseCard(address author) private returns (uint256) {
        // generate new token id
        _tokenIdCount += 1;

        // mint token
        _mint(author, _tokenIdCount, 1, "");

        // connect token to author
        _tokenAuthors[_tokenIdCount] = author;

        // increment total supply
        _totalSupply[_tokenIdCount] += 1;

        emit Release(author, _tokenIdCount, 1);

        return _tokenIdCount;
    }

    function releaseCard()
        public
        whenNotPaused
        whenPublicReleaseEnabled
        returns (uint256)
    {
        // Check if enough value to pay fee

        uint256 tokenId = _releaseCard(msg.sender);

        // send fee to protocol
        payToken.safeTransferFrom(
            msg.sender,
            protocolFeeDestination,
            protocolReleaseCardFee
        );

        return tokenId;
    }

    function getBondingCurvePrice(
        uint256 supply
    ) internal pure returns (uint256) {
        return ((supply ** 3) * 100) / 6;
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : getBondingCurvePrice(supply);
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : getBondingCurvePrice(supply + amount);
        uint256 summation = (sum2 - sum1) / 100;
        return summation * 1 ether * BASE_PRICE_POINTS;
    }

    function getBuyPrice(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(_totalSupply[tokenId], amount);
    }

    function getSellPrice(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(_totalSupply[tokenId] - amount, amount);
    }

    function getBuyPriceAfterFee(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getBuyPrice(tokenId, amount);
        uint256 protocolFee = ((price * protocolTradeCardFeePercent) / 100000);
        uint256 prizePoolFee = ((price * prizePoolTradeCardFeePercent) /
            100000);
        uint256 subjectFee = ((price * authorTradeCardFeePercent) / 100000);
        return price + protocolFee + prizePoolFee + subjectFee;
    }

    function getSellPriceAfterFee(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getSellPrice(tokenId, amount);
        uint256 protocolFee = ((price * protocolTradeCardFeePercent) / 100000);
        uint256 prizePoolFee = ((price * prizePoolTradeCardFeePercent) /
            100000);
        uint256 subjectFee = ((price * authorTradeCardFeePercent) / 100000);
        return price - protocolFee - prizePoolFee - subjectFee;
    }

    function buy(
        address _to,
        uint256 id,
        uint256 amount,
        uint256 maxSpentLimit
    )
        public
        whenNotPaused
        returns (
            uint256 price,
            uint256 protocolFee,
            uint256 prizePoolFee,
            uint256 authorFee
        )
    {
        uint256 supply = _totalSupply[id];
        require(supply > 0, "Card not released");
        require(amount > 0, "Minimum amount is 1");

        price = getBuyPrice(id, amount);

        protocolFee = ((price * protocolTradeCardFeePercent) / 100000);
        prizePoolFee = ((price * prizePoolTradeCardFeePercent) / 100000);
        authorFee = ((price * authorTradeCardFeePercent) / 100000);

        require(
            maxSpentLimit >= price + protocolFee + authorFee + prizePoolFee,
            "Price is too high"
        );

        // mint tokens
        _mint(_to, id, amount, "");

        // Update total supply
        supply = _totalSupply[id] = _totalSupply[id] += amount;

        emit Buy(
            msg.sender,
            _to,
            id,
            amount,
            price,
            protocolFee,
            authorFee,
            supply
        );

        address tokenAuthor = _tokenAuthors[id];

        payToken.safeTransferFrom(msg.sender, address(this), price);
        payToken.safeTransferFrom(msg.sender, tokenAuthor, authorFee);
        payToken.safeTransferFrom(
            msg.sender,
            protocolFeeDestination,
            protocolFee
        );
        payToken.safeTransferFrom(
            msg.sender,
            prizePoolFeeDestination,
            prizePoolFee
        );
    }

    function sell(
        address _to,
        uint256 id,
        uint256 amount,
        uint256 minAmountReceive
    )
        public
        whenNotPaused
        returns (
            uint256 price,
            uint256 protocolFee,
            uint256 prizePoolFee,
            uint256 authorFee
        )
    {
        uint256 supply = _totalSupply[id];

        require(supply > 0, "Card not released");
        require(amount > 0, "Minimum amount is 1");
        require(amount < supply, "Amount exceeds supply");

        uint256 balance = balanceOf(msg.sender, id);

        require(balance >= amount, "Insufficient cards");

        price = getSellPrice(id, amount);

        protocolFee = ((price * protocolTradeCardFeePercent) / 100000);
        prizePoolFee = ((price * prizePoolTradeCardFeePercent) / 100000);
        authorFee = ((price * authorTradeCardFeePercent) / 100000);

        price = price - protocolFee - prizePoolFee - authorFee;

        require(minAmountReceive <= price, "Price is too low");

        // mint tokens
        _burn(msg.sender, id, amount);

        // Update total supply
        supply = _totalSupply[id] = _totalSupply[id] - amount;

        emit Sell(
            msg.sender,
            _to,
            id,
            amount,
            price,
            protocolFee,
            authorFee,
            supply
        );

        address tokenAuthor = _tokenAuthors[id];

        payToken.safeTransfer(_to, price);
        payToken.safeTransfer(tokenAuthor, authorFee);
        payToken.safeTransfer(protocolFeeDestination, protocolFee);
        payToken.safeTransfer(prizePoolFeeDestination, prizePoolFee);
    }

    function releaseCardTo(address author) public onlyAdmin returns (uint256) {
        return _releaseCard(author);
    }

    function getReleaseAuthor(uint256 releaseId) public view returns (address) {
        return _tokenAuthors[releaseId];
    }

    function getReleaseSupply(uint256 releaseId) public view returns (uint256) {
        return _totalSupply[releaseId];
    }
}
