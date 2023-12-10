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
| ProxyAdmin              | 0x19b912EdE7056943B23d237752814438338A9666     |
| ProxyAdmin Owner        | 0x64c6fBb54546d7014b5f89f0db4b40D58c20b1A4     |

### Contract Implementations
| Contract Name           | Implementation Address                         |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0x18B4d142fB3a0337C81a043bF3ceBC39F804BdF7     |
| RSETH                   | 0x5646a74c7B4dB5841e6bDb03A3f9b1ea630DcCeb     |
| LRTDepositPool          | 0xd37b982c54F493cE9D4dCa89a5EA3EA9051fC6bb     |
| LRTOracle               | 0x0bE54b5232771cBab9CEDD789fc5d7695b67463f     |
| ChainlinkPriceOracle    | 0x56e4DF8086a8DD8745cB64661D33F9310dA4AE50     |
| EthXPriceOracle         | 0xEdF8112Ad1Aa7Ac6eb2ea994de8D01d72D01eA40     |
| NodeDelegator           | 0xca7A74BD1f3726C1ce6158de8e745746a8e9396e     |

### Proxy Addresses
| Contract Name           | Proxy Address                                  |
|-------------------------|------------------------------------------------|
| LRTConfig               | 0x3E8b8FE30260d202b92891ab38aE8493c8a0a412     |
| RSETH                   | 0xdc862C46F67a8A7B6412D51D10E1F5e19f1bCb62     |
| LRTDepositPool          | 0x8Ece5A05C62E548944C18504AFE424d0791c1684     |
| LRTOracle               | 0x63F1Cff763Cf282a6CEB6Ba12dE781b79934770f     |
| ChainlinkPriceOracle    | 0x33124283F0c9eef83A5bcd4bb22C23f05ABc7D1A     |
| EthXPriceOracle         | 0x4978F66c51ADd2de0d49ce8Ec0e525E4f6B1Bef7     |

### NodeDelegator Proxy Addresses
- NodeDelegator proxy 1: 0x991837c651902661fa88B80791d58dF56FD0Dd92
- NodeDelegator proxy 2: 0x4929afE2de8CF903dEFFd20e95651283673e47eE
- NodeDelegator proxy 3: 0x9bD27cdc4844967E788958d4b0C60A5898c600E0
- NodeDelegator proxy 4: 0xb3a9DFbCE51ad9Fbb7fAfC6209D1b4cDb6CBF150
- NodeDelegator proxy 5: 0x2e9982418fAeF216d590356D60c008524Bc6dd03


