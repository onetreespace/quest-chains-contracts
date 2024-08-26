// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {IQuestChain} from "./interfaces/IQuestChain.sol";
import {IQuestChainFactory} from "./interfaces/IQuestChainFactory.sol";
import {IQuestChainToken} from "./interfaces/IQuestChainToken.sol";
import {QuestChainToken} from "./QuestChainToken.sol";
import {QuestChainCommons} from "./libraries/QuestChainCommons.sol";

/// @title QuestChainFactory
/// @notice Factory contract for creating and managing quest chains.
/// @dev This contract deploys new quest chain contracts and manages access control.
contract QuestChainFactory is IQuestChainFactory, ReentrancyGuard {

    /********************************
     STATE VARIABLES
     *******************************/

    /// @notice Immutable contract address for quest chain ERC1155 tokens.
    // solhint-disable-next-line immutable-vars-naming
    IQuestChainToken public immutable questChainToken;
    
    /// @notice Immutable template contract address for quest chains.
    // solhint-disable-next-line immutable-vars-naming
    address public immutable questChainTemplate;

    /// @notice Counter for all quest chains.
    uint256 public questChainCount = 0;

    /// @notice Admin address with access control privileges.
    address public admin;
    
    /// @notice Proposed admin address awaiting approval.
    address public proposedAdmin;
    
    /// @notice Timestamp of the last admin proposal.
    uint256 public adminProposalTimestamp;

    uint256 private constant ONE_DAY = 86400;

    /********************************
     MAPPING STRUCTS EVENTS MODIFIER
     *******************************/

    /// @notice Mapping from quest chain counter to deployed quest chains.
    mapping(uint256 => address) private _questChains;

    /// @dev Access control modifier for functions callable by admin only.
    modifier onlyAdmin() {
        if (admin != msg.sender) revert NotAdmin();
        _;
    }

    /// @dev Modifier enforces non-zero address.
    modifier nonZeroAddr(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    /// @dev Modifier enforces two addresses are different.
    modifier mustChangeAddr(address _oldAddress, address _newAddress) {
        if (_oldAddress == _newAddress) revert NoAddressChange();
        _;
    }

    /// @dev Modifier enforces two integers are different.
    modifier mustChangeUint(uint256 _oldUint, uint256 _newUint) {
        if (_oldUint == _newUint) revert NoUintChange();
        _;
    }

    /// @dev Modifier enforces timestamps to be at least a day ago.
    modifier onlyAfterDelay(uint256 _timestamp) {
        if (block.timestamp < _timestamp + ONE_DAY) revert TooSoon();
        _;
    }

    /// @notice Constructor to set up the QuestChainFactory.
    /// @param _template The address of the quest chain template.
    /// @param _admin The address of the initial admin.
    constructor(
        address _template,
        address _admin
    ) nonZeroAddr(_template) nonZeroAddr(_admin) {
        questChainToken = new QuestChainToken();
        questChainTemplate = _template;
        admin = _admin;
        emit FactorySetup();
    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    /// @notice Proposes a new admin address.
    /// @param _admin The address of the new admin.
    function proposeAdminReplace(
        address _admin
    )
        external
        onlyAdmin
        nonZeroAddr(_admin)
        mustChangeAddr(proposedAdmin, _admin)
    {
        proposedAdmin = _admin;
        adminProposalTimestamp = block.timestamp;
        emit AdminReplaceProposed(_admin);
    }

    /// @notice Executes the proposed admin replacement.
    function executeAdminReplace()
        external
        nonZeroAddr(proposedAdmin)
        onlyAfterDelay(adminProposalTimestamp)
        mustChangeAddr(proposedAdmin, admin)
    {
        if (proposedAdmin != msg.sender) revert NotProposedAdmin();
        admin = proposedAdmin;
        delete proposedAdmin;
        delete adminProposalTimestamp;
        emit AdminReplaced(admin);
    }

    /// @notice Deploys a new quest chain minimal proxy.
    /// @param _info The initialization data struct for the new clone.
    /// @param _salt An arbitrary source of entropy.
    /// @return The address of the created quest chain.
    function create(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) external returns (address) {
        return _create(_info, _salt);
    }

    /// @notice Returns the address of a deployed quest chain proxy.
    /// @param _index The quest chain contract index.
    /// @return The address of the quest chain at the given index.
    function getQuestChainAddress(
        uint256 _index
    ) external view returns (address) {
        return _questChains[_index];
    }

    /// @dev Internal function deploys and initializes a new quest chain minimal proxy.
    /// @param _info The initialization data struct for the new clone.
    /// @param _salt An arbitrary source of entropy.
    /// @return The address of the created quest chain.
    function _create(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) internal returns (address) {
        address questChainAddress = _newClone(_salt);
        _setupQuestChain(questChainAddress, _info);
        return questChainAddress;
    }

    /// @dev Internal function deploys a new quest chain minimal proxy.
    /// @param _salt An arbitrary source of entropy.
    /// @return The address of the created clone.
    function _newClone(bytes32 _salt) internal returns (address) {
        return Clones.cloneDeterministic(questChainTemplate, _salt);
    }

    /// @dev Internal function initializes a new quest chain minimal proxy.
    /// @param _questChainAddress The new minimal proxy's address.
    /// @param _info The initialization parameters.
    function _setupQuestChain(
        address _questChainAddress,
        QuestChainCommons.QuestChainInfo calldata _info
    ) internal {
        questChainToken.setTokenOwner(questChainCount, _questChainAddress);
        IQuestChain(_questChainAddress).init(_info);
        _questChains[questChainCount] = _questChainAddress;
        emit QuestChainCreated(questChainCount, _questChainAddress);
        questChainCount++;
    }
}

