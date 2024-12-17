// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/solady/src/utils/ECDSA.sol";
import "lib/solady/src/utils/EIP712.sol";
import "lib/solady/src/accounts/ERC1271.sol";

/**
 * PURPOSE: showcase for the `TypedDataSign` workflow of [EIP-7739](https://eips.ethereum.org/EIPS/eip-7739)
 *  
 * "Account Contract" (`ContractSigner`) implements [1] EIP-1271 and [2] EIP-7739. This lets an EOA who is authorized
 * on this contract (i.e. the return value of `_erc1271Signer`) use EIP-712 typed data signatures to interact with
 * any given protocols, acting on behalf of this contract.
 * 
 * "App Contract" (`MessageBoard`) is an example of an app / protocol smart contract that requires users to use EIP-712
 * typed data signatures to interact with it. This contract calls `EIP1271.isValidSignature` when it detects that it is
 * meant to process a signature made on behalf of a smart contract.
 * 
 * EIP-7739 prevents an EOA's signature (for one specific instance of `ContractSigner`) from being replayed as a signature
 * made on behalf of any other `ContracSigner` contract on which the EOA is authorized.
 */
contract ContractSigner is ERC1271 {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STATE                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address public authorizedSigner;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTRUCTOR                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address _signer) {
        authorizedSigner = _signer;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
    returns (string memory name, string memory version) {
        name = "ContractSigner";
        version = "1";
    }

    function _erc1271Signer() internal view virtual override returns (address) {
        return authorizedSigner;
    }
}

contract MessageBoard is EIP712 {

    using ECDSA for bytes32;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTANTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    bytes4 private constant ERC1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("Message(address sender,uint256 num)");

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          TYPES                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    struct Message {
        address sender;
        uint256 num;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error InvalidEOASigner();
    error InvalidContractSigner();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STATE                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    mapping (address sender => uint num) public numOfSigner;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         TARGET                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function send(Message calldata data, bytes calldata _signature) external {

        bytes32 hash = _hashTypedData(keccak256(abi.encode(
            MESSAGE_TYPEHASH,
            data.sender,
            data.num
        )));
        
        if(data.sender.code.length > 0) {
            if(ERC1271(data.sender).isValidSignature(hash, _signature) != ERC1271_MAGIC_VALUE) {
                revert InvalidContractSigner();
            }
        } else {
            if(hash.recover(_signature) != data.sender) {
                revert InvalidEOASigner();
            }
        }

        numOfSigner[data.sender] = data.num;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
    returns (string memory name, string memory version) {
        name = "MessageBoard";
        version = "1";
    }
}