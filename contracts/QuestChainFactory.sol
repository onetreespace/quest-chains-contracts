// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IQuestChain.sol";
import "./interfaces/IQuestChainFactory.sol";
import "./QuestChainToken.sol";

// author: @dan13ram

/* solhint-disable not-rely-on-time */

contract QuestChainFactory is IQuestChainFactory, ReentrancyGuard {
    using SafeERC20 for IERC20Token;

    /********************************
     STATE VARIABLES
     *******************************/

    // immutable contract address for quest chain ERC1155 tokens
    IQuestChainToken public immutable questChainToken;
    // immutable template contract address for quest chain
    address public immutable questChainTemplate;

    // counter for all quest chains
    uint256 public questChainCount = 0;

    // access control role
    address public admin;
    // proposed admin address
    address public proposedAdmin;
    // timestamp of last admin proposal
    uint256 public adminProposalTimestamp;

    uint256 private constant ONE_DAY = 86400;

    /********************************
     MAPPING STRUCTS EVENTS MODIFIER
     *******************************/

    // mapping from quest chain counter to deployed quest chains
    mapping(uint256 => address) private _questChains;

    /**
     * @dev Access control modifier for functions callable by admin only
     */
    modifier onlyAdmin() {
        require(admin == msg.sender, "QCFactory: not admin");
        _;
    }

    /**
     * @dev Modifier enforces non zero address
     */
    modifier nonZeroAddr(address _address) {
        require(_address != address(0), "QCFactory: 0 address");
        _;
    }

    /**
     * @dev Modifier enforces two addresses are different
     */
    modifier mustChangeAddr(address _oldAddress, address _newAddress) {
        require(_oldAddress != _newAddress, "QCFactory: no change");
        _;
    }

    /**
     * @dev Modifier enforces two integers are different
     */
    modifier mustChangeUint(uint256 _oldUint, uint256 _newUint) {
        require(_oldUint != _newUint, "QCFactory: no change");
        _;
    }

    /**
     * @dev Modifier enforces timestamps be atleast a day ago
     */
    modifier onlyAfterDelay(uint256 _timestamp) {
        require(block.timestamp >= _timestamp + ONE_DAY, "QCFactory: too soon");
        _;
    }

    constructor(
        address _template,
        address _admin
    ) nonZeroAddr(_template) nonZeroAddr(_admin) {
        // deploy the Quest Chain Token and store it's address
        questChainToken = new QuestChainToken();

        // set the quest chain template contract
        questChainTemplate = _template;

        // set the admin address
        admin = _admin;

        // log constructor data
        emit FactorySetup();
    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    /**
     * @dev Proposes a new admin address
     * @param _admin the address of the new admin
     */
    function proposeAdminReplace(
        address _admin
    )
        external
        onlyAdmin
        nonZeroAddr(_admin)
        mustChangeAddr(proposedAdmin, _admin)
    {
        // set proposed admin address
        proposedAdmin = _admin;
        adminProposalTimestamp = block.timestamp;

        // log proposedAdmin change data
        emit AdminReplaceProposed(_admin);
    }

    /**
     * @dev Executes the proposed admin replacement
     */
    function executeAdminReplace()
        external
        nonZeroAddr(proposedAdmin)
        onlyAfterDelay(adminProposalTimestamp)
        mustChangeAddr(proposedAdmin, admin)
    {
        require(proposedAdmin == msg.sender, "QCFactory: !proposedAdmin");

        // replace admin
        admin = proposedAdmin;

        delete proposedAdmin;
        delete adminProposalTimestamp;

        // log admin change data
        emit AdminReplaced(admin);
    }

    /**
     * @dev Deploys a new quest chain minimal proxy
     * @param _info the initialization data struct for our new clone
     * @param _salt an arbitrary source of entropy
     */
    function create(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) external returns (address) {
        // deploy new quest chain minimal proxy
        return _create(_info, _salt);
    }

    /**
     * @dev Returns the address of a deployed quest chain proxy
     * @param _index the quest chain contract index
     */
    function getQuestChainAddress(
        uint256 _index
    ) external view returns (address) {
        return _questChains[_index];
    }

    /**
     * @dev Internal function deploys and initializes a new quest chain minimal proxy
     * @param _info the initialization data struct for our new clone
     * @param _salt an arbitrary source of entropy
     */
    function _create(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) internal returns (address) {
        // deploy a new quest chain clone
        address questChainAddress = _newClone(_salt);

        // initialize the new quest chain clone
        _setupQuestChain(questChainAddress, _info);

        return questChainAddress;
    }

    /**
     * @dev Internal function deploys a new quest chain minimal proxy
     * @param _salt an arbitrary source of entropy
     */
    function _newClone(bytes32 _salt) internal returns (address) {
        return Clones.cloneDeterministic(questChainTemplate, _salt);
    }

    /**
     * @dev Internal function initializes a new quest chain minimal proxy
     * @param _questChainAddress the new minimal proxy's address
     * @param _info the initialization parameters
     */
    function _setupQuestChain(
        address _questChainAddress,
        QuestChainCommons.QuestChainInfo calldata _info
    ) internal {
        // assign the quest chain token owner
        questChainToken.setTokenOwner(questChainCount, _questChainAddress);

        // initialize the quest chain proxy
        IQuestChain(_questChainAddress).init(_info);

        // store the new proxy's address in the quest chain registry
        _questChains[questChainCount] = _questChainAddress;

        // log quest chain creation data
        emit QuestChainCreated(questChainCount, _questChainAddress);

        // increment quest chain counter
        questChainCount++;
    }
}
