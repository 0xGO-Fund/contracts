import hre from "hardhat"

async function main() {
  // Deploy Pool
  const zeroxgoFactory = await hre.ethers.getContractFactory("ZEROxGO")
  const zeroxgo = await zeroxgoFactory.deploy(
    "0xF22Dbcf128c394B067F484FE78586fef86846834",
    "0x9d2133302B0beB040d2E86D1fbC78Da1Dea9Fa3e"
  )
  await zeroxgo.deployed()

  // Deploy Token
  const zeroTokenFactory = await hre.ethers.getContractFactory("ZEROToken")
  const zeroToken = await zeroTokenFactory.deploy()
  await zeroToken.deployed()

  // Deploy MasterChef and Transfer Ownership
  const mcFactory = await hre.ethers.getContractFactory("MasterChef")
  const mc = await mcFactory.deploy(zeroxgo.address, zeroToken.address)
  await mc.deployed()

  // Setup MasterChef
  await zeroxgo.setupMasterChef(mc.address)
  await zeroToken.setupMasterChef(mc.address)

  console.debug({
    zeroxgo: zeroxgo.address,
    zeroToken: zeroToken.address,
    mc: mc.address,
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
