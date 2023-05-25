// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BaseHelper library
 * @dev Some useful functions for the main contract
 */
library BaseHelper {
    string internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts an incoming data to base64 encoded string
     *
     * @param data incoming bytes to encode
     * @return string encoded base64 string
     */
    function encode(bytes memory data)
    internal
    pure
    returns (string memory)
    {
        if (data.length == 0) return "";

        string memory table = TABLE;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                let input := mload(dataPtr)

                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation
     *
     * @param value number to convert
     * @return string
     */
    function toString(uint256 value)
    internal
    pure
    returns (string memory)
    {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Generates a random number from a large number of input parameters
     *
     * @param t usually it is a mint index or token id
     * @param a sender's address
     * @param c some integer that grows
     * @param n some integer that grows
     * @return uint random number
     */
    function strongRandom(uint t, address a, uint c, uint n)
    internal
    view
    returns (uint)
    {
        return uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    t,
                    a,
                    c,
                    n
                )
            )
        );
    }


    /**
     * @dev Returns a substring from position `startIndex` to position `endIndex`
     * @dev The position is counted from 0
     *
     * @param source incoming string
     * @param startIndex the position at which the string will be trimmed
     * @param endIndex the position after which the line will be trimmed
     * @return string
     */
    function substring(
        string memory source,
        uint256 startIndex,
        uint256 endIndex
    )
    internal
    pure
    returns (string memory)
    {
        bytes memory strBytes = bytes(source);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Determines if the call comes from a contract or from a regular account
     *
     * @param account sender's address
     * @return bool if sender is contract
     */
    function isContract(address account)
    internal
    view
    returns (bool)
    {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}