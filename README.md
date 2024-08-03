![](https://img.shields.io/badge/Solidity-informational?style=flat&logo=solidity&logoColor=white&color=6aa6f8)
![](https://img.shields.io/badge/Foundry-informational?style=flat&logo=foundry&logoColor=white&color=6aa6f8)
![](https://img.shields.io/badge/Blockchain-informational?style=flat&logo=blockchain&logoColor=white&color=6aa6f8)
![](https://img.shields.io/badge/Smart_Contracts-informational?style=flat&logo=smartcontracts&logoColor=white&color=6aa6f8)
![](https://img.shields.io/badge/api3-informational?style=flat&logo=api3&logoColor=white&color=6aa6f8)
![](https://img.shields.io/badge/scroll_L2-informational?style=flat&logo=scroll&logoColor=white&color=6aa6f8)

# ChatterPay


Chatterpay is a Wallet for WhatsApp that integrates AI and Account Abstraction, enabling any user to use blockchain easily and securely without technical knowledge.

> Built for: [Level Up Hackathon - Ethereum Argentina 2024](https://ethereumargentina.org/) 

> Build By: [mpefaur](https://github.com/mpefaur), [tomasfrancizco](https://github.com/tomasfrancizco), [TomasDmArg](https://github.com/TomasDmArg), [gonzageraci](https://github.com/gonzageraci),  [dappsar](https://github.com/dappsar)


__Components__:

- Landing Page ([product](https://chatterpay-front-ylswtey2za-uc.a.run.app/), [source code](https://github.com/P4-Games/ChatterPay))
- User Dashboard Website ([product](https://chatterpay-front-ylswtey2za-uc.a.run.app/dashboard), [source code](https://github.com/P4-Games/ChatterPay))
- Backend API ([source code](https://github.com/P4-Games/ChatterPay-Backend)) 
- Smart Contracts ([source code](https://github.com/P4-Games/ChatterPay-SmartContracts)) (this Repo)
- Bot AI (Chatizalo) ([product](https://chatizalo.com/))
- Bot AI Admin Dashboard Website ([product](https://app.chatizalo.com/))


# About this repo

This repository contains the source code of the Smart Contracts.


__Build With__:

- Framework: [Foundry](https://github.com/foundry-rs/foundry)
- Language: [Solidity](https://solidity-es.readthedocs.io/)
- Smart Contracts Library: [OpenZeppelin](https://www.openzeppelin.com/)
- L2 Blockchain: [Scroll](https://github.com/scroll-tech)
- Account Abstraction L2 Keystore: [Scroll L1SLOAD](https://dev.to/turupawn/l1sload-el-nuevo-opcode-para-keystores-seguras-y-escalables-50of)
- Web3 Data Feed: [api3](https://api3.org/)

# Getting Started

__1. Install these Requirements__:

- [git](https://git-scm.com/)
- [foundry](https://book.getfoundry.sh/getting-started/installation)


__2. Clone repository__:

```bash
   git clone https://github.com/P4-Games/ChatterPay-SmartContracts
   cd ChatterPay-SmartContracts
```

__3. Complete .env file__: 

Create a .env file in the root folder and populate it with the following keys and values:


```sh
ETH_SEPOLIA_RPC_URL=Your node provider URL for Sepolia
SCROLL_SEPOLIA_RPC_URL=Your node provider URL for Scroll-Sepolia
PRIVATE_KEY=Your private key
```

__4. Install Dependencies__:


```sh
git submodule update --init --recursive
```

__5. Usage__:

_Build_

```shell
$ forge build
```

_Test_

```shell
$ forge test
```

_Format_

```shell
$ forge fmt
```

_Gas Snapshots_

```shell
$ forge snapshot
```

_Anvil_

```shell
$ anvil
```

_Deploy_

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

_Cast_

```shell
$ cast <subcommand>
```

_Help_

```shell
$ forge --help
$ anvil --help
$ cast --help
```
