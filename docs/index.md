# Solidity API

## UncutsTradingCard

_Contract for managing trading cards using ERC1155 standard with additional functionalities._

### name

```solidity
string name
```

Trading Card Token name

### symbol

```solidity
string symbol
```

Trading Card Token symbol

### protocolReleaseCardFee

```solidity
uint256 protocolReleaseCardFee
```

absolute amount of eth required to mint first card (only for public release)

### protocolTradeCardFeePercent

```solidity
uint32 protocolTradeCardFeePercent
```

protocol fee for every trade in hundred thousand points. 2500 === 0.025 === 2.5%

### prizePoolTradeCardFeePercent

```solidity
uint32 prizePoolTradeCardFeePercent
```

prize pool fee for every trade in hundred thousand points. 2500 === 0.025 === 2.5%

### authorTradeCardFeePercent

```solidity
uint32 authorTradeCardFeePercent
```

author reward fee for every trade in hundred thousand points. 5000 === 0.05 === 5%

### publicReleaseEnabled

```solidity
bool publicReleaseEnabled
```

### protocolFeeDestination

```solidity
address protocolFeeDestination
```

### prizePoolFeeDestination

```solidity
address prizePoolFeeDestination
```

### isPaused

```solidity
bool isPaused
```

### epoch

```solidity
uint256 epoch
```

### payToken

```solidity
contract IERC20 payToken
```

### epochFinish

```solidity
uint256 epochFinish
```

### EPOCH_DURATION

```solidity
uint256 EPOCH_DURATION
```

### Release

```solidity
event Release(address author, uint256 tokenId, uint256 amount)
```

New Card Released Event

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| author | address | card release author address |
| tokenId | uint256 | new card release token id |
| amount | uint256 | the amount of new released cards (always 1) |

### Buy

```solidity
event Buy(address payer, address holder, uint256 tokenId, uint256 amount, uint256 price, uint256 protocolFee, uint256 authorFee, uint256 totalSupply)
```

### Sell

```solidity
event Sell(address payer, address holder, uint256 tokenId, uint256 amount, uint256 price, uint256 protocolFee, uint256 authorFee, uint256 totalSupply)
```

### BatchMetadataUpdate

```solidity
event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)
```

### ToggledPause

```solidity
event ToggledPause(bool oldPauseState, bool newPauseState, address caller)
```

### EpochAdvanced

```solidity
event EpochAdvanced(uint256 newEpoch)
```

### TradingCard__PublicReleaseDisabled

```solidity
error TradingCard__PublicReleaseDisabled()
```

### TradingCard__CardNotReleased

```solidity
error TradingCard__CardNotReleased()
```

### TradingCard__ContractIsPaused

```solidity
error TradingCard__ContractIsPaused()
```

### TradingCard__EpochNotEnded

```solidity
error TradingCard__EpochNotEnded()
```

### TradingCard_OnlyAdmin

```solidity
error TradingCard_OnlyAdmin()
```

### whenNotPaused

```solidity
modifier whenNotPaused()
```

Ensures that the contract is not in a paused state.

### whenPublicReleaseEnabled

```solidity
modifier whenPublicReleaseEnabled()
```

Ensures that the public release is not in a disabled state.

### onlyAdmin

```solidity
modifier onlyAdmin()
```

Ensures that the caller is the admin.

### constructor

```solidity
constructor(string _name, string _symbol, string metadataBaseUrlPrefix, string metadataBaseUrlSuffix, contract IERC20 _payToken, uint128 _BASE_PRICE_POINTS) public
```

UncutsTradingCard constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _name | string | Name of the contract token |
| _symbol | string | Symbol of the contract token |
| metadataBaseUrlPrefix | string | Prefix of the metadata base url |
| metadataBaseUrlSuffix | string | Suffix of the metadata base url |
| _payToken | contract IERC20 | Address of the pay token |
| _BASE_PRICE_POINTS | uint128 | Base price points |

### uri

```solidity
function uri(uint256 tokenId) public view returns (string)
```

Returns the URI of a token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | uint256 |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | string formatted URI of the token including token id and current epoch |

### contractURI

```solidity
function contractURI() public view returns (string)
```

### setProtocolReleaseCardFee

```solidity
function setProtocolReleaseCardFee(uint256 newValue) public
```

### setProtocolTradeCardFeePercent

```solidity
function setProtocolTradeCardFeePercent(uint32 newValue) public
```

### setPrizePoolTradeCardFeePercent

```solidity
function setPrizePoolTradeCardFeePercent(uint32 newValue) public
```

### setAuthorTradeCardFeePercent

```solidity
function setAuthorTradeCardFeePercent(uint32 newValue) public
```

### setProtocolFeeDestination

```solidity
function setProtocolFeeDestination(address newAddress) public returns (address)
```

### setPrizePoolFeeDestination

```solidity
function setPrizePoolFeeDestination(address newAddress) public returns (address)
```

### setAdmin

```solidity
function setAdmin(address newAddress) public
```

### setPublicReleaseStatus

```solidity
function setPublicReleaseStatus(bool newValue) public
```

### advanceEpoch

```solidity
function advanceEpoch() public returns (uint256)
```

### setMetadataBaseUrlPrefix

```solidity
function setMetadataBaseUrlPrefix(string newValue) public
```

### setMetadataBaseUrlSuffix

```solidity
function setMetadataBaseUrlSuffix(string newValue) public
```

### setContractMetadataUrl

```solidity
function setContractMetadataUrl(string newValue) public
```

### setPause

```solidity
function setPause(bool state) public
```

### releaseCard

```solidity
function releaseCard() public returns (uint256)
```

### getBondingCurvePrice

```solidity
function getBondingCurvePrice(uint256 supply) internal view returns (uint256)
```

### getPrice

```solidity
function getPrice(uint256 supply, uint256 amount) internal view returns (uint256)
```

### getBuyPrice

```solidity
function getBuyPrice(uint256 tokenId, uint256 amount) public view returns (uint256)
```

### getSellPrice

```solidity
function getSellPrice(uint256 tokenId, uint256 amount) public view returns (uint256)
```

### getBuyPriceAfterFee

```solidity
function getBuyPriceAfterFee(uint256 tokenId, uint256 amount) public view returns (uint256)
```

### getSellPriceAfterFee

```solidity
function getSellPriceAfterFee(uint256 tokenId, uint256 amount) public view returns (uint256)
```

### buy

```solidity
function buy(address _to, uint256 id, uint256 amount, uint256 maxSpentLimit) public returns (uint256 price, uint256 protocolFee, uint256 prizePoolFee, uint256 authorFee)
```

### sell

```solidity
function sell(address _to, uint256 id, uint256 amount, uint256 minAmountReceive) public returns (uint256 price, uint256 protocolFee, uint256 prizePoolFee, uint256 authorFee)
```

### releaseCardTo

```solidity
function releaseCardTo(address author) public returns (uint256)
```

### getReleaseAuthor

```solidity
function getReleaseAuthor(uint256 releaseId) public view returns (address)
```

### getReleaseSupply

```solidity
function getReleaseSupply(uint256 releaseId) public view returns (uint256)
```

