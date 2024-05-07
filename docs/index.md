# Solidity API

## UncutsTradingCard

Uncuts Trading Card AMM Contract

_Contract for releasing, buying and selling trading cards using ERC1155 standard with ERC20 pay token as payment._

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
contract ERC20Votes payToken
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
event Buy(address payer, address holder, uint256 tokenId, uint256 amount, uint256 price, uint256 protocolFee, uint256 prizePoolFee, uint256 authorFee, uint256 totalSupply)
```

Buy Event Emitted on every card buy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payer | address | wallet address of transaction signer |
| holder | address | wallet address of card receiver |
| tokenId | uint256 | card release ID that had been purchased |
| amount | uint256 | purchased cards count |
| price | uint256 | price for purchased cards excluding fees |
| protocolFee | uint256 | absolute amount of tokens paid to protocol |
| prizePoolFee | uint256 | absolute amount of tokens transferred to prize pool |
| authorFee | uint256 | absolute amount of tokens paid to author |
| totalSupply | uint256 | result total supply of card release after purchased |

### Sell

```solidity
event Sell(address payer, address holder, uint256 tokenId, uint256 amount, uint256 price, uint256 protocolFee, uint256 prizePoolFee, uint256 authorFee, uint256 totalSupply)
```

Sell Event Emitted on every card sell

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payer | address | wallet address of selling cards owner |
| holder | address | the address to which the proceeds from the sale will be transferred. |
| tokenId | uint256 | card release ID that had been selled |
| amount | uint256 | selled cards count |
| price | uint256 | price for selled cards excluding fees |
| protocolFee | uint256 | absolute amount of tokens paid to protocol |
| prizePoolFee | uint256 | absolute amount of tokens transferred to prize pool |
| authorFee | uint256 | absolute amount of tokens paid to author |
| totalSupply | uint256 | result total supply of card release after selled |

### BatchMetadataUpdate

```solidity
event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)
```

Batch Metadata Update Event (Needed to update metadata in time)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _fromTokenId | uint256 | starting card release ID that had been updated |
| _toTokenId | uint256 | ending card release ID that had been updated |

### ToggledPause

```solidity
event ToggledPause(bool oldPauseState, bool newPauseState, address caller)
```

Toggled Pause Event. Emitted when contract is paused/unpaused

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| oldPauseState | bool | old pause state |
| newPauseState | bool | new pause state |
| caller | address | address of the caller |

### EpochAdvanced

```solidity
event EpochAdvanced(uint256 newEpoch)
```

Emitted on every epoch change

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newEpoch | uint256 | new epoch number |

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
constructor(string _name, string _symbol, string metadataBaseUrlPrefix, string metadataBaseUrlSuffix, contract ERC20Votes _payToken, uint128 _BASE_PRICE_POINTS) public
```

UncutsTradingCard constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _name | string | Name of the contract token |
| _symbol | string | Symbol of the contract token |
| metadataBaseUrlPrefix | string | Prefix of the metadata base url |
| metadataBaseUrlSuffix | string | Suffix of the metadata base url |
| _payToken | contract ERC20Votes | Address of the pay token |
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

Returns the contract-level metadata URI

_The contract URI can be set with the setContractMetadataUrl function._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | string formatted URI of the contract metadata |

### setProtocolReleaseCardFee

```solidity
function setProtocolReleaseCardFee(uint256 newValue) public
```

Sets the protocol public release card fee in eth value

_this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | uint256 | new protocol public release card feein eth value |

### setProtocolTradeCardFeePercent

```solidity
function setProtocolTradeCardFeePercent(uint32 newValue) public
```

Sets the protocol fee per trade in base points

_value should be between 0 and 100000
this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | uint32 | new protocol fee per trade in base points |

### setPrizePoolTradeCardFeePercent

```solidity
function setPrizePoolTradeCardFeePercent(uint32 newValue) public
```

Sets the prize pool fee per trade in base points

_value should be between 0 and 100000
this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | uint32 | new prize pool fee per trade in base points |

### setAuthorTradeCardFeePercent

```solidity
function setAuthorTradeCardFeePercent(uint32 newValue) public
```

Sets the card author fee per trade in base points

_value should be between 0 and 100000
this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | uint32 | new card author fee per trade in base points |

### setProtocolFeeDestination

```solidity
function setProtocolFeeDestination(address newAddress) public returns (address)
```

Sets the protocol fee destination

_address should not be 0
this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newAddress | address | new protocol fee destination address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address |

### setPrizePoolFeeDestination

```solidity
function setPrizePoolFeeDestination(address newAddress) public returns (address)
```

Sets the prize pool fee destination

_address should not be 0
this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newAddress | address | new prize pool fee destination address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address |

### setAdmin

```solidity
function setAdmin(address newAddress) public
```

Sets the admin

_address should not be 0
this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newAddress | address | new admin address |

### setPublicReleaseStatus

```solidity
function setPublicReleaseStatus(bool newValue) public
```

Enable/disable public release

_this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | bool | new public release status |

### advanceEpoch

```solidity
function advanceEpoch() public returns (uint256)
```

Advance epoch

_epoch will be incremented if enough time has passed
this method can be called by anyone_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 epoch |

### setMetadataBaseUrlPrefix

```solidity
function setMetadataBaseUrlPrefix(string newValue) public
```

Set metadata base url prefix

_This method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | string | new metadata base url prefix |

### setMetadataBaseUrlSuffix

```solidity
function setMetadataBaseUrlSuffix(string newValue) public
```

Set metadata base url suffix

_This method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | string | new metadata base url suffix |

### setContractMetadataUrl

```solidity
function setContractMetadataUrl(string newValue) public
```

Set contract-level metadata url

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newValue | string | new contract-level metadata url |

### setPause

```solidity
function setPause(bool state) public
```

Toggles pause

_this method should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| state | bool | new pause state |

### releaseCard

```solidity
function releaseCard() public returns (uint256)
```

Release card function

_this method should be called by the card author
this method can be called by anyone
this method can only be called if public release is enabled
this method can only be called if the contract is not paused
this method can only be called if paytoken balance is enough and allowance is enough_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 tokenId |

### getBondingCurvePrice

```solidity
function getBondingCurvePrice(uint256 supply) internal view returns (uint256)
```

Basic bonding curve price formula (1,2,4,7,11,16,22...)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| supply | uint256 | supply of bonding curve |

### getPrice

```solidity
function getPrice(uint256 supply, uint256 amount) internal view returns (uint256)
```

Get price of cards

_this method can be called by anyone
should return 0 if result supply is 0_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| supply | uint256 | supply of bonding curve |
| amount | uint256 | amount of tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price price of tokens in paytoken |

### getBuyPrice

```solidity
function getBuyPrice(uint256 tokenId, uint256 amount) public view returns (uint256)
```

Get buy price of cards

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | card release ID |
| amount | uint256 | amount of cards |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price buy price of cards in paytoken wei without fees |

### getSellPrice

```solidity
function getSellPrice(uint256 tokenId, uint256 amount) public view returns (uint256)
```

Get sell price of cards

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | card release ID |
| amount | uint256 | amount of cards |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price sell price of cards in paytoken wei without fees |

### getBuyPriceAfterFee

```solidity
function getBuyPriceAfterFee(uint256 tokenId, uint256 amount) public view returns (uint256)
```

Get buy price of cards after fees

_this method can be called by anyone
should return 0 if result supply is 0_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | card release ID |
| amount | uint256 | amount of cards |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price buy price of cards in paytoken wei with fees |

### getSellPriceAfterFee

```solidity
function getSellPriceAfterFee(uint256 tokenId, uint256 amount) public view returns (uint256)
```

Get sell price of cards after fees

_this method can be called by anyone
should return 0 if result supply is 0_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | card release ID |
| amount | uint256 | amount of cards |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price sell price of cards in paytoken wei with fees |

### buy

```solidity
function buy(address _to, uint256 id, uint256 amount, uint256 maxSpentLimit) public returns (uint256 price, uint256 protocolFee, uint256 prizePoolFee, uint256 authorFee)
```

Buy card function

_this method should only called if contract is not paused
minimum amount is 1
sender should have enough paytoken balance and allowance_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | wallet address of card receiver |
| id | uint256 | card release ID |
| amount | uint256 | amount of cards |
| maxSpentLimit | uint256 | max amount of paytoken to spend (slippage) |

### sell

```solidity
function sell(address _to, uint256 id, uint256 amount, uint256 minAmountReceive) public returns (uint256 price, uint256 protocolFee, uint256 prizePoolFee, uint256 authorFee)
```

Sell card function

_this method should only called if contract is not paused
minimum amount is 1
last card in release can not be sold
sender should have enough card balance_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | wallet address of proceeds receiver |
| id | uint256 | card release ID |
| amount | uint256 | amount of cards |
| minAmountReceive | uint256 | min amount of paytoken to receive (slippage) |

### releaseCardTo

```solidity
function releaseCardTo(address author) public returns (uint256)
```

_only admin can release cards to another address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| author | address | card release author address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | new card release ID |

### getReleaseAuthor

```solidity
function getReleaseAuthor(uint256 releaseId) public view returns (address)
```

Get card release author

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| releaseId | uint256 | card release ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | author address of card release author |

### getReleaseSupply

```solidity
function getReleaseSupply(uint256 releaseId) public view returns (uint256)
```

Get card release supply

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| releaseId | uint256 | card release ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | supply of cards for provided id |

### delegate

```solidity
function delegate(address delegatee) external
```

Function to delegate votes (preserving lose of voting power)

_this function should only be called by the owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delegatee | address | address of delegatee |

