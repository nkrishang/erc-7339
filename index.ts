import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { createPublicClient, createWalletClient, http } from "viem";

import * as TypedData from "ox/TypedData";
import * as AbiParameters from "ox/AbiParameters";

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                        CONSTANTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

const ANVIL_TEST_PRIVATE_KEY =
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

const APP_CONTRACT =
  "0xe7f1725e7734ce288f8367e1bb143e90bb3f0512" as `0x${string}`;
const ACCOUNT_CONTRACT =
  "0x5fbdb2315678afecb367f032d93f642f64180aa3" as `0x${string}`;

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*             1. Create account EIP-7739 payload to sign             */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

const contents = {
  sender: ACCOUNT_CONTRACT,
  num: BigInt(Math.floor(Math.random() * 10000)),
};

const appDomain = {
  name: "MessageBoard",
  version: "1",
  chainId: 31337,
  verifyingContract: APP_CONTRACT,
};

const accountDomain = {
  name: "ContractSigner",
  version: "1",
  chainId: 31337n,
  verifyingContract: ACCOUNT_CONTRACT,
  salt: "0x0000000000000000000000000000000000000000000000000000000000000000" as `0x${string}`, // specifically for solady/Eip712
};

const typedData = {
  domain: appDomain,
  types: {
    TypedDataSign: [
      {
        name: "contents",
        type: "Message",
      },
      {
        name: "name",
        type: "string",
      },
      {
        name: "version",
        type: "string",
      },
      {
        name: "chainId",
        type: "uint256",
      },
      {
        name: "verifyingContract",
        type: "address",
      },
      {
        name: "salt",
        type: "bytes32",
      },
    ],
    Message: [
      {
        name: "sender",
        type: "address",
      },
      {
        name: "num",
        type: "uint256",
      },
    ],
  },
  primaryType: "TypedDataSign" as const,
  message: {
    contents: contents,
    ...accountDomain,
  },
};

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*     2. Sign payload and create encoded signature object    */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

const account = privateKeyToAccount(ANVIL_TEST_PRIVATE_KEY);
const rawSignature = await account.signTypedData(typedData);

const contentsHash = TypedData.hashStruct({
  data: contents,
  primaryType: "Message" as const,
  types: {
    Message: [
      {
        name: "sender",
        type: "address",
      },
      {
        name: "num",
        type: "uint256",
      },
    ],
  },
});

const appDomainHash = TypedData.hashDomain({
  domain: appDomain,
});

const contentsDescription = "Message(address sender,uint256 num)";

const encodedSignature = AbiParameters.encodePacked(
  ["bytes", "bytes32", "bytes32", "string", "uint16"],
  [
    rawSignature,
    appDomainHash,
    contentsHash,
    contentsDescription,
    contentsDescription.length,
  ]
);

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                   3. Send transaction                      */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

const publicClient = createPublicClient({
  chain: anvil,
  transport: http("http://localhost:8545"),
});

export const walletClient = createWalletClient({
  chain: anvil,
  transport: http("http://localhost:8545"),
});

const { request } = await publicClient.simulateContract({
  account,
  address: APP_CONTRACT,
  abi: [
    {
      type: "function",
      name: "send",
      inputs: [
        {
          name: "data",
          type: "tuple",
          internalType: "struct MessageBoard.Message",
          components: [
            { name: "sender", type: "address", internalType: "address" },
            { name: "num", type: "uint256", internalType: "uint256" },
          ],
        },
        { name: "_signature", type: "bytes", internalType: "bytes" },
      ],
      outputs: [],
      stateMutability: "nonpayable",
    },
  ],
  functionName: "send",
  args: [contents, encodedSignature],
});

const transactionHash = await walletClient.writeContract(request);
const receipt = await publicClient.waitForTransactionReceipt({
  hash: transactionHash,
});

if (receipt.status === "success") {
  const num = await publicClient.readContract({
    address: APP_CONTRACT,
    abi: [
      {
        type: "function",
        name: "numOfSigner",
        inputs: [{ name: "sender", type: "address", internalType: "address" }],
        outputs: [{ name: "num", type: "uint256", internalType: "uint256" }],
        stateMutability: "view",
      },
    ],
    functionName: "numOfSigner",
    args: [ACCOUNT_CONTRACT],
  });

  if (num != contents.num) {
    throw new Error(
      "Something went wrong. Contract didn't set state as anticipated."
    );
  } else {
    console.log("Number for signer: ", num.toString());
  }
} else {
  throw new Error("Something went wrong. Transaction reverted.");
}
