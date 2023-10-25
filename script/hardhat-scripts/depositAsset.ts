import { ethers } from 'hardhat'

async function main() {
  const lrtDepositPool = process.env.LRT_DEPOSIT_POOL ?? ''
  const lrtDepositPoolFactory = await ethers.getContractFactory('LRTDepositPool')
  const lrtDepositPoolInstance = await lrtDepositPoolFactory.attach(lrtDepositPool)
  const depositTx = await lrtDepositPoolInstance.depositAsset('',ethers.utils.parseEther('0.005'))
  depositTx.wait()
  console.log(`deposited ${ethers.utils.parseEther('0.005')} successfully`)
}

main()
