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
| ProxyAdmin              | 0x503DCfd945dC6612FAa18823501C05410D7eB646     |
| ProxyAdmin Owner        | 0x7E9bb9673aC38071a7699e6A3C48b8fBDE574Cd0     |

### Contract Implementations
| Contract Name           | Implementation Address                         |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0xEfd3A812e072cf7E303508faAb6290caEEafB83A     |
| RSETH                   | 0x261fCBe803844441ba3ff353707E03f68dD8A1d4     |
| LRTDepositPool          | 0xD92D5DBdDAf5A8d405a98e4EDa098EB54e823b8b     |
| LRTOracle               | 0xB6060b2360672D6cA6cB065B4de10Fb83B704707     |
| ChainlinkPriceOracle    | 0x5B45B7D8828F7BA5398d56fc7E11e2BA663a9135     |
| NodeDelegator           | 0x89545Da6Ac844EBd93580Fb7F2d75b9F244a8292     |

### Proxy Addresses
| Contract Name           | Proxy Address                                  |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0x99Abf439a4e9910934Dea47082286a04986820b5     |
| RSETH                   | 0xDa3FF613C5A44F743E5F46c43D1f6F897F425205     |
| LRTDepositPool          | 0x907db5022b333128300eE7E5458cef8c32ff5A86     |
| LRTOracle               | 0xE64060B802563d6B74d5CC72F0ba27a5a1B5B7f7     |
| ChainlinkPriceOracle    | 0x2d81a54C2b722417295F9bF1dE5CEf98690774e9     |

### NodeDelegator Proxy Addresses
- NodeDelegator proxy 1: 0x89cD79e873DEA08D1AfA173B9160c8D31e4Bc9f0
- NodeDelegator proxy 2: 0x5c5720246d3210E90875015c8439230c027a104b
- NodeDelegator proxy 3: 0x68FBD2a42e5d598dA91161f69a8346aFc9Ad9BA8
- NodeDelegator proxy 4: 0x6E6a5770A3A9A8b8614600d5F0A9d6bDc695CF68
- NodeDelegator proxy 5: 0x51975b2e6E29738B8aaaC8479f929a04c5E1D54c