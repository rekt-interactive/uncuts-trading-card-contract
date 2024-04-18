import hre, { ethers } from "hardhat";
import dotenv from 'dotenv'

dotenv.config()

// function delay(ms: number) {
//   let timer = ms / 1000
//   let interval = setInterval(() => {
//     timer--
//     console.log(`Waiting for ${timer} seconds...`)
//   }, 1000)
//   return new Promise((resolve) => {
//     clearInterval(interval)
//     setTimeout(resolve, ms)
//   });
// }

async function main() {

  const payToken = await ethers.deployContract("PayToken", ['UNCUTS', 'UNCUTS', 18]);

  payToken.waitForDeployment();

  const payTokenAddress = await payToken.getAddress();

  console.log(
    `UNCUTS pay token contract deployed to ${payTokenAddress}`
  );

  const constructorArgs = [
    process.env.TOKEN_NAME,
    process.env.TOKEN_SYMBOL,
    process.env.METADATA_PREFIX,
    '/metadata/',
    payTokenAddress,
    '250'
  ];


  const tradingCardContract = await ethers.deployContract("UncutsTradingCard", constructorArgs);

  await tradingCardContract.waitForDeployment();

  await tradingCardContract.setPrizePoolFeeDestination(process.env.PRIZE_POOL_FEE_DESTINATION!)
  await tradingCardContract.setAdmin(process.env.ADMIN_ADDRESS!)
  await tradingCardContract.setProtocolFeeDestination(process.env.PROTOCOL_FEE_DESTINATION!)

  const contractAddress = await tradingCardContract.getAddress();

  console.log(
    `Contract UncutsTradingCard  deployed to ${contractAddress}`
  );

  // await delay(30000); // Wait for 30 seconds before verifying the contract

  // hre.run("verify:verify", {
  //   address: contractAddress,
  //   constructorArguments: constructorArgs,
  // })

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
