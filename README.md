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

| Contract Name           |  Address                                       |
|-------------------------|------------------------------------------------|
| ProxyFactory            | 0x4ae77FdfB3BBBe99598CAfaE4c369b604b6d9e02     |
| ProxyAdmin              | 0x065564470CcB29f2DFFf4718fFF3a455Da302797     |
| ProxyAdmin Owner        | 0x7E9bb9673aC38071a7699e6A3C48b8fBDE574Cd0     |

### Contract Implementations
| Contract Name           | Implementation Address                         |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0x35A1d9fa91F1790F28aD749cE0677f598161Dd52     |
| RSETH                   | 0xf6252a139aD0137fCbB57a4537Af56Bb9b09Fb8E     |
| LRTDepositPool          | 0xf115C6a675f0300AB9108bd039d273e6503d3cC3     |
| LRTOracle               | 0xE8ae65459F9293FDdD10dF4698A81CBBd7373c4A     |
| ChainlinkPriceOracle    | 0x108c4D9C2c1C51f9AF16eBe3C31C3ef47236c75b     |
| NodeDelegator           | 0xeB7393db16cEB301D546cdEd3C140bfBAa9a33E3     |

### Proxy Addresses
| Contract Name           | Proxy Address                                  |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0x90B1dF320af8Bcac033D8d8527A57EFC12cde10D     |
| RSETH                   | 0xf1A97B476367114c8a9B4B5a00E3112C6Cd7bA23     |
| LRTDepositPool          | 0x1AFa0314010BcD6d28Fdda63D7695D7d2DaaB3d3     |
| LRTOracle               | 0xF79b3b6E0afab2Cbe2aa09A7d8eF5d11a172557c     |
| ChainlinkPriceOracle    | 0x61f0Cf0cf9b8F2084B387C453C4805efcC4e523f     |

### NodeDelegator Proxy Addresses
- NodeDelegator proxy 1: 0xA2Bb150D3ddC6B3db45100C4768149f3a67618a5
- NodeDelegator proxy 2: 0x9452494232D9c0A1eB711319E5C8eA703e4E4a63
- NodeDelegator proxy 3: 0x53E3D324601b7ca7e0Ce1099D7477B7264571D2e
- NodeDelegator proxy 4: 0x3AD3F863bD386318e78E6aa8c2f78D4B95f65f9A
- NodeDelegator proxy 5: 0xc70b0143988A15c6b7979b5fEAe5C60ff07c7C79