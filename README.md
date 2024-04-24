# Uncuts Hardhat Project

## Testing contracts

1. copy .env.example to .env
2. fill out env variables
  - OWNER_PRIVATE_KEY - private key of contract deployer
  - ADMIN_ADDRESS - any public address to check admin rights
  - PROTOCOL_FEE_DESTINATION - any public address to test protocol fees
  - PRIZE_POOL_FEE_DESTINATION - any public address to test prize pool

3. run
```shell
npx harhat compile
npx hardhat test
```

Default hardhat commands:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
```
