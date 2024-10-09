-include .env

deploy_arbitrum_sepolia :; forge clean && forge script script/DeployChatterPay.s.sol --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

## --verify --etherscan-api-key $(ARBISCAN_API_KEY)