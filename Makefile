-include .env

deploy_verify_arbitrum_sepolia :; forge script script/DeployChatterPay.s.sol --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ARBISCAN_API_KEY) --broadcast
deploy_arbitrum_sepolia :; forge script script/DeployChatterPay.s.sol --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast