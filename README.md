# EIP-7739 Example

> A defensive rehashing scheme which prevents signature replays across smart accounts and preserves the readability of the signed contents
>
> See [https://eips.ethereum.org/EIPS/eip-7739](https://eips.ethereum.org/EIPS/eip-7739)

This repo is a showcase for the `TypedDataSign` workflow of [EIP-7739](https://eips.ethereum.org/EIPS/eip-7739).

- "Account Contract" (`ContractSigner`) implements [1] EIP-1271 and [2] EIP-7739. This lets an EOA who is authorized on this contract (i.e. the return value of `_erc1271Signer`) use EIP-712 typed data signatures to interact with any given protocols, acting on behalf of this contract.

- "App Contract" (`MessageBoard`) is an example of an app / protocol smart contract that requires users to use EIP-712 typed data signatures to interact with it. This contract calls `EIP1271.isValidSignature` when it detects that it is meant to process a signature made on behalf of a smart contract.

EIP-7739 prevents an EOA's signature (for one specific instance of `ContractSigner`) from being replayed as a signature made on behalf of any other `ContracSigner` contract on which the EOA is authorized.

## Install

This project uses Foundry and Bun. It and uses `forge` and `anvil` for local development. See [https://book.getfoundry.sh/](https://book.getfoundry.sh/) and [https://bun.sh/](https://bun.sh/) for installation isntructions.

1. Clone this repository:

```bash
git clone ...
```

2. Install smart contract dependencies

```bash
forge build
```

3. Install TypeScript dependencies

```bash
bun i
```

## Run

1. Run `anvil` to start up local node.

```bash
anvil
```

2. Run the following to deploy the two main contracts of this project (`ContractSigner` and `MessageBoard`) onto the local node.

```bash
forge script script/LocalDeploy.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

> ⚠️ Note: we're using the private key of one of anvil's local test signers. Please do not paste your personal private key.

This creates `broadcast/script/LocalDeploy.s.sol/run-latest.json` where you'll find the address of your two deployments.

3. Update `index.ts` with APP_CONTRACT (`MessageBoard`) and ACCOUNT_CONTRACT (`ContractSigner`) addresses and run the following:

```bash
bun run index.ts
```

This script interacts with `MessageBoard` using an EIP-712 signature made on behalf of `ContractSigner`.

## Sources

- [ERC-7739: Readable Typed Signatures for Smart Accounts](https://eips.ethereum.org/EIPS/eip-7739)
- [https://github.com/frangio/eip712-wrapper-for-eip1271](https://github.com/frangio/eip712-wrapper-for-eip1271) which does not seem to work with Solady's ERC-1271 implementation, hence this example repo.
