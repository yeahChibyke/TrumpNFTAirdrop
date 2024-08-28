-include .env

deploy:
	forge script script/DeployTrumpd.s.sol:DeployTrumpd --rpc-url $(SEP_RPC_URL) --account key --verify --etherscan-api-key $(SEP_VER_KEY) --broadcast -vvvv

test: 
	forge test --rpc-url $(SEP_RPC_URL)

generate-input:
	forge script script/GenerateInput.s.sol:GenerateInput -vv
