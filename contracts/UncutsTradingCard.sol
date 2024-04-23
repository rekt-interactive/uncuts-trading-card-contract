// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @notice Uncuts Trading Card AMM Contract
 * @dev Contract for releasing, buying and selling trading cards using ERC1155 standard with ERC20 pay token as payment.
 */
contract UncutsTradingCard is ERC1155, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    /// @notice Trading Card Token name
    string public name = "TradingCard";

    /// @notice Trading Card Token symbol
    string public symbol = "TC";

    //private vars
    /// @dev Card Release ID counter
    uint256 private _tokenIdCount = 0;

    /// @dev Card Release Authors storage
    mapping(uint256 => address) private _tokenAuthors;

    /// @dev Card Release total supplies storage
    mapping(uint256 => uint256) private _totalSupply;

    /// @dev The initial price of card in paytoken
    uint128 private BASE_PRICE_POINTS = 1000;

    /// @dev Admin has permission to release cards
    address private _admin = msg.sender;

    string private _metadataBaseUrlPrefix = "";
    string private _metadataBaseUrlSuffix = "";
    string private _contractMetadataUrl = "";

    //public vars
    /// @notice absolute amount of eth required to mint first card (only for public release)
    uint256 public protocolReleaseCardFee = 0.005 ether;

    /// @notice protocol fee for every trade in hundred thousand points. 2500 === 0.025 === 2.5%
    uint32 public protocolTradeCardFeePercent = 2500;

    /// @notice prize pool fee for every trade in hundred thousand points. 2500 === 0.025 === 2.5%
    uint32 public prizePoolTradeCardFeePercent = 2500;

    /// @notice author reward fee for every trade in hundred thousand points. 5000 === 0.05 === 5%
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
    /// New Card Released Event
    /// @param author card release author address
    /// @param tokenId new card release token id
    /// @param amount the amount of new released cards (always 1)
    event Release(address author, uint256 tokenId, uint256 amount);

    /// Buy Event Emitted on every card buy
    /// @param payer wallet address of transaction signer
    /// @param holder wallet address of card receiver
    /// @param tokenId card release ID that had been purchased
    /// @param amount purchased cards count
    /// @param price price for purchased cards excluding fees
    /// @param protocolFee absolute amount of tokens paid to protocol
    /// @param prizePoolFee  absolute amount of tokens transferred to prize pool
    /// @param authorFee  absolute amount of tokens paid to author
    /// @param totalSupply result total supply of card release after purchased
    event Buy(
        address payer,
        address holder,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 prizePoolFee,
        uint256 authorFee,
        uint256 totalSupply
    );

    /// Sell Event Emitted on every card sell
    /// @param payer wallet address of selling cards owner
    /// @param holder the address to which the proceeds from the sale will be transferred.
    /// @param tokenId card release ID that had been selled
    /// @param amount selled cards count
    /// @param price price for selled cards excluding fees
    /// @param protocolFee absolute amount of tokens paid to protocol
    /// @param prizePoolFee  absolute amount of tokens transferred to prize pool
    /// @param authorFee  absolute amount of tokens paid to author
    /// @param totalSupply result total supply of card release after selled
    event Sell(
        address payer,
        address holder,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 prizePoolFee,
        uint256 authorFee,
        uint256 totalSupply
    );

    /// Batch Metadata Update Event (Needed to update metadata in time)
    /// @param _fromTokenId starting card release ID that had been updated
    /// @param _toTokenId ending card release ID that had been updated
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// Toggled Pause Event. Emitted when contract is paused/unpaused
    /// @param oldPauseState old pause state
    /// @param newPauseState new pause state
    /// @param caller address of the caller
    event ToggledPause(bool oldPauseState, bool newPauseState, address caller);

    /// Emitted on every epoch change
    /// @param newEpoch new epoch number
    event EpochAdvanced(uint256 newEpoch);

    //errors
    error TradingCard__PublicReleaseDisabled();
    error TradingCard__CardNotReleased();

    error TradingCard__ContractIsPaused();
    error TradingCard__EpochNotEnded();
    error TradingCard_OnlyAdmin();

    /// @notice Ensures that the contract is not in a paused state.
    modifier whenNotPaused() {
        if (isPaused) revert TradingCard__ContractIsPaused();
        _;
    }

    /// @notice Ensures that the public release is not in a disabled state.
    modifier whenPublicReleaseEnabled() {
        if (!publicReleaseEnabled) revert TradingCard__PublicReleaseDisabled();
        _;
    }

    /// @notice Ensures that the caller is the admin.
    modifier onlyAdmin() {
        if (msg.sender != _admin) revert TradingCard_OnlyAdmin();
        _;
    }

    //constructor
    /// @notice UncutsTradingCard constructor
    /// @param _name Name of the contract token
    /// @param _symbol Symbol of the contract token
    /// @param metadataBaseUrlPrefix Prefix of the metadata base url
    /// @param metadataBaseUrlSuffix Suffix of the metadata base url
    /// @param _payToken Address of the pay token
    /// @param _BASE_PRICE_POINTS Base price points
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

    /**
     * @notice Returns the URI of a token
     * @param tokenId uint256
     * @return string formatted URI of the token including token id and current epoch
     */
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

    /**
     * @notice Returns the contract-level metadata URI
     * @return string formatted URI of the contract metadata
     * @dev The contract URI can be set with the setContractMetadataUrl function.
     */
    function contractURI() public view returns (string memory) {
        return _contractMetadataUrl;
    }

    /// @notice Sets the protocol public release card fee in eth value
    /// @param newValue new protocol public release card feein eth value
    /// @dev this method should only be called by the owner
    function setProtocolReleaseCardFee(uint256 newValue) public onlyOwner {
        protocolReleaseCardFee = newValue;
    }

    /// @notice Sets the protocol fee per trade in base points
    /// @param newValue new protocol fee per trade in base points
    /// @dev value should be between 0 and 100000
    /// @dev this method should only be called by the owner
    function setProtocolTradeCardFeePercent(uint32 newValue) public onlyOwner {
        require(newValue <= 100000, "Value must be between 0 and 100000");
        protocolTradeCardFeePercent = newValue;
    }

    /// @notice Sets the prize pool fee per trade in base points
    /// @param newValue new prize pool fee per trade in base points
    /// @dev value should be between 0 and 100000
    /// @dev this method should only be called by the owner
    function setPrizePoolTradeCardFeePercent(uint32 newValue) public onlyOwner {
        require(newValue <= 100000, "Value must be between 0 and 100000");
        prizePoolTradeCardFeePercent = newValue;
    }

    /// @notice Sets the card author fee per trade in base points
    /// @param newValue new card author fee per trade in base points
    /// @dev value should be between 0 and 100000
    /// @dev this method should only be called by the owner
    function setAuthorTradeCardFeePercent(uint32 newValue) public onlyOwner {
        require(newValue <= 100000, "Value must be between 0 and 100000");
        authorTradeCardFeePercent = newValue;
    }

    /// @notice Sets the protocol fee destination
    /// @param newAddress new protocol fee destination address
    /// @return address
    /// @dev address should not be 0
    /// @dev this method should only be called by the owner
    function setProtocolFeeDestination(
        address newAddress
    ) public onlyOwner returns (address) {
        require(newAddress != address(0), "Invalid address");
        protocolFeeDestination = newAddress;
        return protocolFeeDestination;
    }

    /// @notice Sets the prize pool fee destination
    /// @param newAddress new prize pool fee destination address
    /// @return address
    /// @dev address should not be 0
    /// @dev this method should only be called by the owner
    function setPrizePoolFeeDestination(
        address newAddress
    ) public onlyOwner returns (address) {
        require(newAddress != address(0), "Invalid address");
        prizePoolFeeDestination = newAddress;
        return prizePoolFeeDestination;
    }

    /// @notice Sets the admin
    /// @param newAddress new admin address
    /// @dev address should not be 0
    /// @dev this method should only be called by the owner
    function setAdmin(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Invalid address");
        _admin = newAddress;
    }

    /// @notice Enable/disable public release
    /// @param newValue new public release status
    /// @dev this method should only be called by the owner
    function setPublicReleaseStatus(bool newValue) public onlyOwner {
        publicReleaseEnabled = newValue;
    }

    /// @notice Advance epoch
    /// @dev epoch will be incremented if enough time has passed
    /// @dev this method can be called by anyone
    /// @return uint256 epoch
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

    /// @notice Set metadata base url prefix
    /// @dev This method should only be called by the owner
    /// @param newValue new metadata base url prefix
    function setMetadataBaseUrlPrefix(string memory newValue) public onlyOwner {
        _metadataBaseUrlPrefix = newValue;
        emit BatchMetadataUpdate(0, _tokenIdCount);
    }

    /// @notice Set metadata base url suffix
    /// @dev This method should only be called by the owner
    /// @param newValue new metadata base url suffix
    function setMetadataBaseUrlSuffix(string memory newValue) public onlyOwner {
        _metadataBaseUrlSuffix = newValue;
        emit BatchMetadataUpdate(0, _tokenIdCount);
    }

    /// @notice Set contract-level metadata url
    /// @param newValue new contract-level metadata url
    function setContractMetadataUrl(string memory newValue) public onlyOwner {
        _contractMetadataUrl = newValue;
    }

    /// @notice Toggles pause
    /// @dev this method should only be called by the owner
    /// @param state new pause state
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

    /// @notice Release card function
    /// @dev this method should be called by the card author
    /// @return uint256 tokenId
    /// @dev this method can be called by anyone
    /// @dev this method can only be called if public release is enabled
    /// @dev this method can only be called if the contract is not paused
    /// @dev this method can only be called if paytoken balance is enough and allowance is enough
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

    /// Basic bonding curve price formula (1,2,4,7,11,16,22...)
    /// @param supply supply of bonding curve
    function getBondingCurvePrice(
        uint256 supply
    ) internal view returns (uint256) {
        return
            (supply *
                ((BASE_PRICE_POINTS * supply ** 2) +
                    (2 * BASE_PRICE_POINTS) +
                    (3 * supply * BASE_PRICE_POINTS) +
                    (6 * BASE_PRICE_POINTS) -
                    (3 * BASE_PRICE_POINTS * supply) -
                    (3 * BASE_PRICE_POINTS))) / 6;
    }

    /// Get price of cards
    /// @param supply supply of bonding curve
    /// @param amount amount of tokens
    /// @return price price of tokens in paytoken
    /// @dev this method can be called by anyone
    /// @dev should return 0 if result supply is 0
    function getPrice(
        uint256 supply,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : getBondingCurvePrice(supply - 1);
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : getBondingCurvePrice(supply - 1 + amount);
        uint256 summation = (sum2 - sum1);
        return summation * 1 ether;
    }

    /// Get buy price of cards
    /// @param tokenId card release ID
    /// @param amount amount of cards
    /// @return price buy price of cards in paytoken wei without fees
    function getBuyPrice(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(_totalSupply[tokenId], amount);
    }

    /// Get sell price of cards
    /// @param tokenId card release ID
    /// @param amount amount of cards
    /// @return price sell price of cards in paytoken wei without fees
    function getSellPrice(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(_totalSupply[tokenId] - amount, amount);
    }

    /// Get buy price of cards after fees
    /// @param tokenId card release ID
    /// @param amount amount of cards
    /// @return price buy price of cards in paytoken wei with fees
    /// @dev this method can be called by anyone
    /// @dev should return 0 if result supply is 0
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

    /// Get sell price of cards after fees
    /// @param tokenId card release ID
    /// @param amount amount of cards
    /// @return price sell price of cards in paytoken wei with fees
    /// @dev this method can be called by anyone
    /// @dev should return 0 if result supply is 0
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

    /// Buy card function
    /// @param _to wallet address of card receiver
    /// @param id card release ID
    /// @param amount amount of cards
    /// @param maxSpentLimit max amount of paytoken to spend (slippage)
    /// @dev this method should only called if contract is not paused
    /// @dev minimum amount is 1
    /// @dev sender should have enough paytoken balance and allowance
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
            prizePoolFee,
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

    /// Sell card function
    /// @param _to wallet address of proceeds receiver
    /// @param id card release ID
    /// @param amount amount of cards
    /// @param minAmountReceive min amount of paytoken to receive (slippage)
    /// @dev this method should only called if contract is not paused
    /// @dev minimum amount is 1
    /// @dev last card in release can not be sold
    /// @dev sender should have enough card balance
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
            prizePoolFee,
            authorFee,
            supply
        );

        address tokenAuthor = _tokenAuthors[id];

        payToken.safeTransfer(_to, price);
        payToken.safeTransfer(tokenAuthor, authorFee);
        payToken.safeTransfer(protocolFeeDestination, protocolFee);
        payToken.safeTransfer(prizePoolFeeDestination, prizePoolFee);
    }

    /// @dev only admin can release cards to another address
    /// @param author card release author address
    /// @return new card release ID
    function releaseCardTo(address author) public onlyAdmin returns (uint256) {
        return _releaseCard(author);
    }

    /// Get card release author
    /// @param releaseId card release ID
    /// @return author address of card release author
    function getReleaseAuthor(uint256 releaseId) public view returns (address) {
        return _tokenAuthors[releaseId];
    }

    /// Get card release supply
    /// @param releaseId card release ID
    /// @return supply of cards for provided id
    function getReleaseSupply(uint256 releaseId) public view returns (uint256) {
        return _totalSupply[releaseId];
    }
}
