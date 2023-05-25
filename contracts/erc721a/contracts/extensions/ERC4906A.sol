// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3 
// Creator: Chiru Labs
// EIP-4906 support added by: rocky_sys

pragma solidity ^0.8.4;

import './IERC4906A.sol';
import '../ERC721A.sol';

/**
 * @title ERC4906A
 *
 * @dev [ERC4906](https://eips.ethereum.org/EIPS/eip-4906) 
 * It adds a MetadataUpdate event to EIP-721A tokens.
 */
abstract contract ERC4906A is ERC721A, IERC4906A {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return super.supportsInterface(interfaceId) || interfaceId == 0x49064906; // ERC4906 interface ID for ERC721.
    }
}