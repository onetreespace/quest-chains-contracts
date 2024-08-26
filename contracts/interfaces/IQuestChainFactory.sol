// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {IQuestChainToken} from "./IQuestChainToken.sol";
import {QuestChainCommons} from "../libraries/QuestChainCommons.sol";

interface IQuestChainFactoryFunctions {
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

/// @title IQuestChainFactorySignals
/// @notice Interface for QuestChainFactory signals including events and errors.
interface IQuestChainFactorySignals {
    /// @notice Emitted when the factory is set up.
    event FactorySetup();

    /// @notice Emitted when a new admin address is proposed.
    /// @param proposedAdmin The address of the proposed new admin.
    event AdminReplaceProposed(address proposedAdmin);

    /// @notice Emitted when the admin is replaced.
    /// @param newAdmin The address of the new admin.
    event AdminReplaced(address newAdmin);

    /// @notice Emitted when a new quest chain is created.
    /// @param questChainCount The index of the created quest chain.
    /// @param questChainAddress The address of the created quest chain.
    event QuestChainCreated(uint256 questChainCount, address questChainAddress);

    /// @notice Error thrown when a zero address is provided.
    error ZeroAddress();

    /// @notice Error thrown when no change is detected in the provided address.
    error NoAddressChange();

    /// @notice Error thrown when no change is detected in the provided uint value.
    error NoUintChange();

    /// @notice Error thrown when a non-admin attempts to call a restricted function.
    error NotAdmin();

    /// @notice Error thrown when an action is attempted too soon.
    error TooSoon();

    /// @notice Error thrown when the caller is not the proposed admin.
    error NotProposedAdmin();
}

// solhint-disable-next-line no-empty-blocks
interface IQuestChainFactory is
    IQuestChainFactoryFunctions,
    IQuestChainFactorySignals
{}
