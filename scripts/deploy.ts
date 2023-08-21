import { ethers, upgrades } from 'hardhat'

async function main() {

  console.log('starting deployment process...')
  const staderAdmin = process.env.STADER_ADMIN ?? ''
  const rETH = process.env.R_ETH ?? ''
  const stETH = process.env.ST_ETH ?? ''
  const cbETH = process.env.CB_ETH ?? ''
  const lrtConfigFactory = await ethers.getContractFactory('LRTConfig')

  const lrtConfig = await upgrades.deployProxy(lrtConfigFactory, [staderAdmin, stETH, rETH, cbETH])
  console.log('LRT config deployed at ', lrtConfig.address)

  const rsETHFactory = await ethers.getContractFactory('RSETH')
  const rsETHToken = await upgrades.deployProxy(rsETHFactory, [staderAdmin,lrtConfig.address])
  console.log('rsETH Token deployed at ', rsETHToken.address)

  const lrtDepositPoolFactory = await ethers.getContractFactory('LRTDepositPool')
  const lrtDepositPool = await upgrades.deployProxy(lrtDepositPoolFactory, [lrtConfig.address])
  console.log('lrtDepositPool deployed at ', lrtDepositPool.address)

  const lrtOracleFactory = await ethers.getContractFactory('LRTOracle')
  const lrtOracle = await upgrades.deployProxy(lrtOracleFactory, [lrtConfig.address])
  console.log('lrtOracle deployed at ', lrtOracle.address)

  const nodeDelegatorFactory = await ethers.getContractFactory('NodeDelegator')
  const nodeDelegator = await upgrades.deployProxy(nodeDelegatorFactory, [lrtConfig.address])
  console.log('nodeDelegator deployed at ', nodeDelegator.address)
  const nodeDelegator2 = await upgrades.deployProxy(nodeDelegatorFactory, [lrtConfig.address])
  console.log('nodeDelegator2 deployed at ', nodeDelegator2.address)
  const nodeDelegator3 = await upgrades.deployProxy(nodeDelegatorFactory, [lrtConfig.address])
  console.log('nodeDelegator3 deployed at ', nodeDelegator3.address)

}

main()
