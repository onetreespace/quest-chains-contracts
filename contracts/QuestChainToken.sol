// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {ERC1155, IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {IQuestChainToken} from "./interfaces/IQuestChainToken.sol";
import {IQuestChainFactory} from "./interfaces/IQuestChainFactory.sol";

/// @title QuestChainToken
/// @notice ERC1155 token contract for QuestChain, designed to be non-transferable (SoulBound).
/// @dev Manages quest token ownership and metadata.
contract QuestChainToken is IQuestChainToken, ERC1155 {
    /// @notice Immutable contract address for the quest chain factory.
    // solhint-disable-next-line style-guide-casing,immutable-vars-naming
    IQuestChainFactory public immutable questChainFactory;

    /********************************
     MAPPING STRUCTS EVENTS MODIFIER
     *******************************/

    /// @notice Metadata URI for each token kind.
    mapping(uint256 => string) private _tokenURIs;

    /// @notice Mapping from token ID to the owner address.
    mapping(uint256 => address) private _tokenOwners;

    /// @dev Access control modifier for functions callable by the factory contract only.
    modifier onlyFactory() {
        if (msg.sender != address(questChainFactory)) revert NotFactory();
        _;
    }

    /// @dev Access control modifier for functions callable by token owners only.
    /// @param _tokenId The quest token ID.
    modifier onlyTokenOwner(uint256 _tokenId) {
        if (msg.sender != _tokenOwners[_tokenId])
            revert NotTokenOwner(_tokenId);
        _;
    }

    /// @notice Constructor to set up the QuestChainToken contract.
    constructor() ERC1155("") {
        questChainFactory = IQuestChainFactory(msg.sender);
    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    /// @notice Assigns quest chain ownership.
    /// @param _tokenId The quest NFT identifier.
    /// @param _questChain The address of the new QuestChain minimal proxy.
    function setTokenOwner(
        uint256 _tokenId,
        address _questChain
    ) public onlyFactory {
        _tokenOwners[_tokenId] = _questChain;
    }

    /// @notice Assigns the metadata location for a quest line.
    /// @param _tokenId The quest NFT identifier.
    /// @param _tokenURI The URI pointer for locating token metadata.
    function setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) public onlyTokenOwner(_tokenId) {
        _tokenURIs[_tokenId] = _tokenURI;
        emit URI(uri(_tokenId), _tokenId);
    }

    /// @notice Mints a quest achievement token to the user.
    /// @param _user The address of a successful questing user.
    /// @param _tokenId The quest token identifier.
    function mint(
        address _user,
        uint256 _tokenId
    ) public onlyTokenOwner(_tokenId) {
        if (balanceOf(_user, _tokenId) != 0) revert AlreadyMinted();
        _mint(_user, _tokenId, 1, "");
    }

    /// @notice Burns a quest achievement token from the user.
    /// @param _user The address of a successful questing user.
    /// @param _tokenId The quest token identifier.
    function burn(
        address _user,
        uint256 _tokenId
    ) public onlyTokenOwner(_tokenId) {
        if (balanceOf(_user, _tokenId) != 1) revert TokenNotFound();
        _burn(_user, _tokenId, 1);
    }

    /*************************
     VIEW AND PURE FUNCTIONS
     *************************/

    /// @notice Returns the owner address of a particular quest token.
    /// @param _tokenId The quest token identifier.
    /// @return The address of the token owner.
    function tokenOwner(uint256 _tokenId) public view returns (address) {
        return _tokenOwners[_tokenId];
    }

    /// @notice Returns the metadata URI of a particular quest token.
    /// @param _tokenId The quest token identifier.
    /// @return The URI of the token.
    function uri(
        uint256 _tokenId
    )
        public
        view
        override(IERC1155MetadataURI, ERC1155)
        returns (string memory)
    {
        return _tokenURIs[_tokenId];
    }

    /*************************
     OVERRIDES
     *************************/

    /// @dev Prevents transferring the tokens and thus makes them SoulBound.
    function _update(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values
    ) internal override {
        if (_to != address(0) && _from != address(0)) revert SoulBound();
        super._update(_from, _to, _ids, _values);
    }

    /// @dev Prevents approval of the tokens and thus makes them SoulBound.
    function _setApprovalForAll(address, address, bool) internal pure override {
        revert SoulBound();
    }
}
