require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

module.exports = {
	solidity: {
		version: "0.8.20",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
	networks: {
		arbitrumSepolia: {
			url: "https://sepolia-rollup.arbitrum.io/rpc",
			accounts: [process.env.PRIVATE_KEY]
		},
		scrollSepolia: {
			url: "https://sepolia-rpc.scroll.io/",
			accounts: [process.env.PRIVATE_KEY]
		}
	},
	etherscan: {
		apiKey: {
			arbitrumSepolia: process.env.ARBISCAN_API_KEY,
			scrollSepolia: process.env.SCROLLSCAN_API_KEY
		},
		customChains: [
			{
				network: "scrollSepolia",
				chainId: 534351,
				urls: {
					apiURL: "https://api-sepolia.scrollscan.com/api",
					browserURL: "https://sepolia.scrollscan.com/"
				}
			}
		]
	},
	paths: {
		sources: "./contracts",
		tests: "./test",
		cache: "./cache",
		artifacts: "./artifacts"
	},
	mocha: {
		timeout: 40000
	}
};