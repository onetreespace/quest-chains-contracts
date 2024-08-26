// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {IQuestChainFactory} from "./IQuestChainFactory.sol";
import {IERC1155MetadataURI}  from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface IQuestChainTokenFunctions is IERC1155MetadataURI {
    function setTokenOwner(uint256 _tokenId, address _questChain) external;

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    function mint(address _user, uint256 _tokenId) external;

    function burn(address _user, uint256 _tokenId) external;

    function questChainFactory() external view returns (IQuestChainFactory);

    function tokenOwner(uint256 _tokenId) external view returns (address);
}

/// @title IQuestChainTokenSignals
/// @notice Interface for QuestChainToken signals including events and errors.
interface IQuestChainTokenSignals {
    /// @notice Error thrown when the caller is not the factory contract.
    error NotFactory();

    /// @notice Error thrown when the caller is not the owner of the token.
    /// @param tokenId The ID of the token for which ownership was checked.
    error NotTokenOwner(uint256 tokenId);

    /// @notice Error thrown when a token is already minted to the user.
    error AlreadyMinted();

    /// @notice Error thrown when a token is not found for the user.
    error TokenNotFound();

    /// @notice Error thrown when trying to transfer or approve a SoulBound token.
    error SoulBound();
}


// solhint-disable-next-line no-empty-blocks
interface IQuestChainToken is IQuestChainTokenFunctions, IQuestChainTokenSignals {}
