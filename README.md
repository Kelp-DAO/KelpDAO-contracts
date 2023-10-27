# LRT-ETH

## Setup

1. Install dependencies

```bash
npm install
```

1. copy .env.example to .env and fill in the values

```bash
cp .env.example .env
```

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

## Deploy to testnet

```bash
make deploy-lrt-testnet
```

## Deploy to Anvil:

```bash
make deploy-lrt-local-test
```

### General Deploy Script Instructions

Create a Deploy script in `script/Deploy.s.sol`:

and run the script:

```sh
$ forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.


## Verify Contracts

Follow this pattern
`contractAddress=<contractAddress> contractPath=<contract-path> make verify-lrt-proxy-testnet`

Example:
```bash
contractAddress=0xE7b647ab9e0F49093926f06E457fa65d56cb456e contractPath=contracts/LRTConfig.sol:LRTConfig  make verify-lrt-proxy-testnet
```


### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ npm lint
```

### Test

Run the tests:

```sh
$ forge test
```

Generate test coverage and output result to the terminal:

```sh
$ npm test:coverage
```

Generate test coverage with lcov report (you'll have to open the `./coverage/index.html` file in your browser, to do so
simply copy paste the path):

```sh
$ npm test:coverage:report
```

## Deployed Contracts

### Goerli testnet

### Contract Implementations
| Contract Name           | Implementation Address                        |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0x61120bACcd738CB92083D7a8EB8663A5A23EBcEf     |
| RSETH                   | 0x0C11b8a6985967faf1f4a49E24d30e97f98d6074     |
| LRTDepositPool          | 0x017C78252F56448F90F15b8Bf2FAFfaC7d2d2D1E     |
| LRTOracle               | 0x8Fd6A75f11F9627F807f3247dE49b55425bE5D67     |
| ChainlinkPriceOracle    | 0x98c0D1Ef4D1db3cf38f2C913C7F35b11D202B49e     |
| NodeDelegator           | 0x55079e56eE5A144DA27663E0A26b48E75d8b382d     |
| predictedRSETHAddress   | 0xe2762edA68Be993dC07A80a5c709C0dB4366c8B1     |

### Proxy Addresses
| Contract Name           | Proxy Address                                  |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0xE7b647ab9e0F49093926f06E457fa65d56cb456e      |
| RSETH                   | 0x8650BF0Af73cBa1eEAeedd1058B21DE32813cB21      |
| LRTDepositPool          | 0xe5382121fB5b8a2d63a2ECAD49B27d91edeA51bD      |
| LRTOracle               | 0xDE801062128e69A7a53cAf03eab376dC0f22601A      |
| ChainlinkPriceOracle    | 0x52f84eBEd2aEc0a58B5589E0E744797934ABEE35      |

### NodeDelegator Proxy Addresses
- NodeDelegator proxy 1: 0x3E1e35C66658508aFfc8b1bf0ad0Fc3D3DC6F3cC
- NodeDelegator proxy 2: 0x6AD2FC0b26d2903b3357015A050EB72A6D549719
- NodeDelegator proxy 3: 0x24526937FD63d8e16EF3081dAF58F151FF531484
- NodeDelegator proxy 4: 0x7A80D3DaC7cD55A388e544f054AEEbEB39972C68
- NodeDelegator proxy 5: 0xe9D244e47F18767602AbE70B81c78F343F7a837b