// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "./IERC20Token.sol";
import "./IQuestChainToken.sol";
import "../libraries/QuestChainCommons.sol";

interface IQuestChainFactory {
    event FactorySetup();
    event QuestChainCreated(uint256 index, address questChain);
    event AdminReplaceProposed(address proposedAdmin);
    event AdminReplaced(address admin);

    function create(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) external returns (address);

    function getQuestChainAddress(
        uint256 _index
    ) external view returns (address);

    function questChainCount() external view returns (uint256);

    function questChainTemplate() external view returns (address);

    function questChainToken() external view returns (IQuestChainToken);

    function admin() external view returns (address);
}
