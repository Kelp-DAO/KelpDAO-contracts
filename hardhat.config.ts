import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-solhint";
import "@nomicfoundation/hardhat-foundry";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.21",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  defaultNetwork: "goerli",
  networks: {
    hardhat: {},
    goerli: {
      url: process.env.PROVIDER_URL_TESTNET ?? "",
      accounts: [process.env.OWNER_PRIVATE_KEY_TESTNET],
    },
    mainnet: {
      url: process.env.PROVIDER_URL_MAINNET ?? "",
      accounts: [process.env.OWNER_PRIVATE_KEY_MAINNET],
    },
  },
  etherscan: {
    apiKey: {
      goerli: `${process.env.GOERLI_ETHERSCAN_API_KEY}`,
      mainnet: `${process.env.ETHERSCAN_API_KEY}`,
    },
  },
};

export default config;
