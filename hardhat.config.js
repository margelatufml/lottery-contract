require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()
const GOERELI_RPC_URL = process.env.GOERELI_RPC_URL || "RPC_example"
const PRIVATE_KEY = process.env.PRIVATE_KEY || "key_exmpl"
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "API_EXPL"
const COIN_KEY = process.env.COIN_KEY || "API_EXPL"
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            blockConirmations: 1,
        },
        goerli: {
            chainId: 5,
            blockConfirmations: 6,
            url: GOERELI_RPC_URL,
            accounts: [PRIVATE_KEY],
        },
    },
    etherscan: {
        // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            goerli: ETHERSCAN_API_KEY,
        },
        customChains: [
            {
                network: "goerli",
                chainId: 5,
                urls: {
                    apiURL: "https://api-goerli.etherscan.io/api",
                    browserURL: "https://goerli.etherscan.io",
                },
            },
        ],
    },
    gasReporter: {
        enabled: false,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        //coinmarketcap:process.env.COIN_KEY
    },
    solidity: "0.8.4",
    namedAccounts: {
        deployer: { default: 0 },
        player: { default: 1 },
    },
    mocha: {
        timeout: 300000, //200 seconds max
    },
}
