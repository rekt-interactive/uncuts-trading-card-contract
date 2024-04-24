import { getContract, createWalletClient, createPublicClient, http } from "viem"
import {privateKeyToAccount} from 'viem/accounts'
import { UncutsTradingCard__factory } from "../typechain-types"
import {baseSepolia} from 'viem/chains'
import dotenv from 'dotenv'

dotenv.config()

function delay(ms: number) {
  let timer = ms / 1000
  let interval = setInterval(() => {
    timer--
    console.log(`Waiting for ${timer} seconds...`)
  }, 1000)
  return new Promise((resolve) => {
    clearInterval(interval)
    setTimeout(resolve, ms)
  });
}

async function main(){

  const publicClient = createPublicClient({
    transport: http('https://sepolia.base.org')
  })
  const account = privateKeyToAccount(`0x${process.env.OWNER_PRIVATE_KEY}`)

  const client = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http()
  })

  const contract = getContract(
    {
      client: publicClient,
      address: '0x5870f52F23c1F601CbE4C740bC49370Ec034EfF4',
      abi: UncutsTradingCard__factory.abi
    }
  )

  let pp_destination = await contract.read.prizePoolFeeDestination()

  console.log(pp_destination)

}

main()