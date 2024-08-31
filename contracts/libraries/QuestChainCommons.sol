// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

library QuestChainCommons {
    struct QuestChainInfo {
        address[] owners;
        address[] admins;
        address[] editors;
        address[] reviewers;
        string[] quests;
        bool paused;
        string details;
        string tokenURI;
    }

    error BadSignature();

    function recoverParameters(
        bytes memory _signature
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65) {
            revert BadSignature();
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }
}
