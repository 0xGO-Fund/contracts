import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"

const INFURA_URL = process.env.INFURA_URL!

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY!,
  },
  networks: {
    hardhat: {
      forking: {
        url: INFURA_URL,
        enabled: true,
      },
    },
    goerli: {
      url: INFURA_URL,
      accounts: [process.env.DEPLOYER_PK!],
    },
  },
}

export default config
