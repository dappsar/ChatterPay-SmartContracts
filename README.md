![](https://img.shields.io/badge/Solidity-informational?style=flat&logo=solidity&logoColor=white&color=363636)
![](https://img.shields.io/badge/Foundry-informational?style=flat&logo=foundry&logoColor=white&color=1b1f23)
![](https://img.shields.io/badge/Blockchain-informational?style=flat&logo=blockchain&logoColor=white&color=3b3b3b)
![](https://img.shields.io/badge/Smart_Contracts-informational?style=flat&logo=smartcontracts&logoColor=white&color=4c4c4c)


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
