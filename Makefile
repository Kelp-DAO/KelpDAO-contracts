# include .env file and export its env vars
# (-include to ignore error if it does not exist)
# Note that any unset variables here will wipe the variables if they are set in
# .zshrc or .bashrc. Make sure that the variables are set in .env, especially if
# you're running into issues with fork tests
-include .env

# forge coverage

coverage :; forge coverage --report lcov && lcov --remove lcov.info  -o lcov.info 'test/*' 'script/*'

# deployment commands
deploy-lrt-testnet :; forge script script/foundry-scripts/DeployLRT.s.sol:DeployLRT --rpc-url goerli  --private-key ${DEPLOYER_PRIVATE_KEY} --broadcast --verify -vvv

deploy-lrt-local-test :; forge script script/foundry-scripts/DeployLRT.s.sol:DeployLRT --rpc-url localhost --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  --froms 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast -vvv

# deployment commands:LRTDepositPool
deploy-lrt-depositPool-testnet :; forge script script/foundry-scripts/DeployLRTDepositPool.s.sol:DeployLRTDepositPool --rpc-url goerli  --private-key ${DEPLOYER_PRIVATE_KEY} --broadcast --verify -vvv

deploy-lrt-depositPool-local-test :; forge script script/foundry-scripts/DeployLRTDepositPool.s.sol:DeployLRTDepositPool --rpc-url localhost --private-key 0x1cad05fbd3a79cef2336fd10a58b618c55fa548923b861ea83db9ae54597a4ed  --froms 0x7E9bb9673aC38071a7699e6A3C48b8fBDE574Cd0 --broadcast -vvv

# upgrade commands
upgrade-lrt-testnet :; forge script script/foundry-scripts/UpgradeLRT.s.sol:UpgradeLRT --rpc-url goerli  --private-key ${DEPLOYER_PRIVATE_KEY} --broadcast --verify -vvv

upgrade-lrt-local-test :; forge script script/foundry-scripts/UpgradeLRT.s.sol:UpgradeLRT --rpc-url localhost --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  --froms 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast -vvv

# verify commands
## example: contractAddress=<contractAddress> contractPath=<contract-path> make verify-lrt-proxy-testnet
## example: contractAddress=0xE7b647ab9e0F49093926f06E457fa65d56cb456e contractPath=contracts/LRTConfig.sol:LRTConfig  make verify-lrt-proxy-testnet
verify-lrt-proxy-testnet :; forge verify-contract --chain-id 5 --watch --etherscan-api-key ${GOERLI_ETHERSCAN_API_KEY} ${contractAddress} ${contractPath}
