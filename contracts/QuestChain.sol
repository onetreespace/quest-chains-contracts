// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IQuestChain.sol";
import "./interfaces/ILimiter.sol";

/// @title QuestChain Contract
/// @notice Manages quests within a quest chain, including creation, editing, submission, and review of quests.
/// @dev This contract interacts with IQuestChainToken and IQuestChainFactory to manage quest chain tokens and factory functions.
contract QuestChain is
    IQuestChain,
    ReentrancyGuard,
    Initializable,
    Pausable,
    AccessControl
{
    /********************************
     CONSTANT VARIABLES
     *******************************/

    /// @notice Role key for the admin role.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// @notice Role key for the editor role.
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    /// @notice Role key for the reviewer role.
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

    /********************************
     STATE VARIABLES
     *******************************/

    /// @notice Interface for interacting with the quest chain factory.
    IQuestChainFactory public questChainFactory;
    /// @notice Interface for interacting with the quest chain token.
    IQuestChainToken public questChainToken;
    /// @notice Identifier for the quest chain and its corresponding token.
    uint256 public questChainId;
    /// @notice Counter for all quests.
    uint256 public questCount;
    /// @notice Address of the limiter contract, if any.
    address public limiterContract;

    /// @notice Array of quests.
    QuestDetails[] public questDetails;

    /// @notice Mapping from user address to a mapping of quest ID to quest completion status.
    mapping(address => mapping(uint256 => QuestStatus)) private _questStatus;

    /********************************
     MODIFIERS
     *******************************/

    /// @dev Modifier to allow function call only by the factory contract.
    modifier onlyFactory() {
        if (_msgSender() != address(questChainFactory)) revert NotFactory();
        _;
    }

    /// @dev Modifier to allow function call only when the quest is valid.
    modifier validQuest(uint256 _questId) {
        if (_questId >= questCount) revert QuestNotFound(_questId);
        _;
    }

    /// @dev Modifier to allow function call only when the quester has completed prerequisite quests.
    modifier questerCanSubmit(address _quester, uint _questId) {
        uint256[] memory prereqQuests = questDetails[_questId].prereqQuests;

        if (prereqQuests.length > 0) {
            for (uint256 i = 0; i < prereqQuests.length; i++) {
                if (_questStatus[_quester][prereqQuests[i]] != QuestStatus.pass)
                    revert PrereqQuestsNotPassed(_quester, _questId);
            }
        }

        _;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the quest chain with provided information.
    /// @param _info Struct containing quest chain information such as owners, admins, editors, reviewers, and quests.
    function init(
        QuestChainCommons.QuestChainInfo calldata _info
    ) external initializer {
        questChainFactory = IQuestChainFactory(_msgSender());
        questChainToken = IQuestChainToken(questChainFactory.questChainToken());
        questChainId = questChainFactory.questChainCount();

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(EDITOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REVIEWER_ROLE, ADMIN_ROLE);

        _setTokenURI(_info.tokenURI);

        if (_info.owners.length == 0) revert NoOwners();

        for (uint256 i = 0; i < _info.owners.length; i = i + 1) {
            _grantRole(DEFAULT_ADMIN_ROLE, _info.owners[i]);
            _grantRole(ADMIN_ROLE, _info.owners[i]);
            _grantRole(EDITOR_ROLE, _info.owners[i]);
            _grantRole(REVIEWER_ROLE, _info.owners[i]);
        }

        for (uint256 i = 0; i < _info.admins.length; i = i + 1) {
            _grantRole(ADMIN_ROLE, _info.admins[i]);
            _grantRole(EDITOR_ROLE, _info.admins[i]);
            _grantRole(REVIEWER_ROLE, _info.admins[i]);
        }

        for (uint256 i = 0; i < _info.editors.length; i = i + 1) {
            _grantRole(EDITOR_ROLE, _info.editors[i]);
            _grantRole(REVIEWER_ROLE, _info.editors[i]);
        }

        for (uint256 i = 0; i < _info.reviewers.length; i = i + 1) {
            _grantRole(REVIEWER_ROLE, _info.reviewers[i]);
        }

        questCount = questCount + _info.quests.length;
        if (_info.paused) {
            _pause();
        }

        emit QuestChainInit(_info.details, _info.quests, _info.paused);
    }

    /// @notice Pauses the contract, disabling certain functions.
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract, enabling certain functions.
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Edits the quest chain details.
    /// @param _details URI of off-chain details for the quest chain.
    function edit(string calldata _details) external onlyRole(ADMIN_ROLE) {
        emit QuestChainEdited(_msgSender(), _details);
    }

    /// @notice Sets a limiter contract for the quest chain.
    /// @param _limiterContract Address of the limiter contract.
    function setLimiter(
        address _limiterContract
    ) external onlyRole(ADMIN_ROLE) {
        limiterContract = _limiterContract;
        emit SetLimiter(_limiterContract);
    }

    /// @notice Creates new quests in the quest chain.
    /// @param _detailsList List of URIs of off-chain details for new quests.
    function createQuests(
        string[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        questCount += _detailsList.length;
        emit QuestsCreated(_msgSender(), _detailsList);
    }

    /// @notice Edits existing quests in the quest chain.
    /// @param _questIdList List of quest IDs to be edited.
    /// @param _detailsList List of URIs of off-chain details for each quest.
    function editQuests(
        uint256[] calldata _questIdList,
        string[] calldata _detailsList
    ) external onlyRole(EDITOR_ROLE) {
        uint256 _loopLength = _questIdList.length;

        if (_loopLength != _detailsList.length) revert InvalidParams();

        for (uint256 i; i < _loopLength; ) {
            if (_questIdList[i] >= questCount)
                revert QuestNotFound(_questIdList[i]);
            unchecked {
                ++i;
            }
        }

        emit QuestsEdited(_msgSender(), _questIdList, _detailsList);
    }

    /// @notice Configures quests in the quest chain.
    /// @param _questIdList List of quest IDs to be configured.
    /// @param _questDetails List of details for each quest.
    function configureQuests(
        uint256[] calldata _questIdList,
        QuestDetails[] calldata _questDetails
    ) external onlyRole(EDITOR_ROLE) {
        uint256 _loopLength = _questIdList.length;

        if (_loopLength != _questDetails.length) revert InvalidParams();

        for (uint256 i; i < _loopLength; ) {
            if (_questIdList[i] >= questCount)
                revert QuestNotFound(_questIdList[i]);

            questDetails[_questIdList[i]] = QuestDetails(
                _questDetails[i].prereqQuests,
                _questDetails[i].disabled,
                _questDetails[i].optional,
                _questDetails[i].skipReview
            );

            unchecked {
                ++i;
            }
        }
        emit ConfiguredQuests(_msgSender(), _questIdList, _questDetails);
    }

    /// @notice Submits proofs for completing particular quests in the quest chain.
    /// @param _quester Address of the quester submitting the proof.
    /// @param _questIdList List of quest IDs for the quest submissions.
    /// @param _proofList List of off-chain proofs for each quest.
    function submitProofs(
        address _quester,
        uint256[] calldata _questIdList,
        string[] calldata _proofList
    ) external whenNotPaused {
        if (limiterContract != address(0)) {
            ILimiter(limiterContract).submitProofLimiter(
                _msgSender(),
                _questIdList
            );
        }

        uint256 _loopLength = _questIdList.length;

        if (_loopLength != _proofList.length) revert InvalidParams();

        for (uint256 i; i < _loopLength; ) {
            _submitProof(_quester, _questIdList[i]);
            unchecked {
                ++i;
            }
        }

        emit QuestProofsSubmitted(_msgSender(), _questIdList, _proofList);
    }

    /// @notice Reviews proofs submitted by questers for the quest chain.
    /// @param _questerList List of questers whose submissions are being reviewed.
    /// @param _questIdList List of quest IDs for the quest submissions.
    /// @param _successList List of booleans accepting or rejecting submissions.
    /// @param _detailsList List of off-chain comments for each submission.
    function reviewProofs(
        address[] calldata _questerList,
        uint256[] calldata _questIdList,
        bool[] calldata _successList,
        string[] calldata _detailsList
    ) external onlyRole(REVIEWER_ROLE) {
        uint256 _loopLength = _questerList.length;

        if (
            _loopLength != _questIdList.length ||
            _loopLength != _successList.length ||
            _loopLength != _detailsList.length
        ) revert InvalidParams();

        for (uint256 i; i < _loopLength; ) {
            _reviewProof(_questerList[i], _questIdList[i], _successList[i]);
            unchecked {
                ++i;
            }
        }

        emit QuestProofsReviewed(
            _msgSender(),
            _questerList,
            _questIdList,
            _successList,
            _detailsList
        );
    }

    /// @notice Sets the token URI for the quest chain NFT.
    /// @param _tokenURI Off-chain token URI.
    function setTokenURI(
        string memory _tokenURI
    ) external onlyRole(ADMIN_ROLE) {
        _setTokenURI(_tokenURI);
    }

    /// @notice Mints an NFT to the sender if they have completed all quests.
    function mintToken() external {
        if (questCount == 0) revert NoQuestsFound();

        bool atLeastOnePassed;

        for (uint256 _questId; _questId < questCount; ++_questId) {
            if (
                !questDetails[_questId].optional &&
                !questDetails[_questId].disabled &&
                _questStatus[_msgSender()][_questId] != QuestStatus.pass
            ) revert ChainIncomplete();

            if (
                !atLeastOnePassed &&
                _questStatus[_msgSender()][_questId] == QuestStatus.pass
            ) atLeastOnePassed = true;
        }

        if (!atLeastOnePassed) revert NoSuccessfulReview();

        questChainToken.mint(_msgSender(), questChainId);
    }

    /// @notice Burns the NFT from the sender.
    function burnToken() external {
        questChainToken.burn(_msgSender(), questChainId);
    }

    /// @notice Gets the status of a quest for a specific quester.
    /// @param _quester The address of the quester.
    /// @param _questId The ID of the quest.
    /// @return status The status of the quest.
    function questStatus(
        address _quester,
        uint256 _questId
    ) external view validQuest(_questId) returns (QuestStatus status) {
        status = _questStatus[_quester][_questId];
    }

    /// @notice Grants cascading roles to a user.
    /// @param _role The role to be granted.
    /// @param _account The address of the user.
    function grantRole(
        bytes32 _role,
        address _account
    ) public override onlyRole(getRoleAdmin(_role)) {
        _grantRole(_role, _account);
        if (_role == DEFAULT_ADMIN_ROLE) {
            grantRole(ADMIN_ROLE, _account);
        } else if (_role == ADMIN_ROLE) {
            grantRole(EDITOR_ROLE, _account);
        } else if (_role == EDITOR_ROLE) {
            grantRole(REVIEWER_ROLE, _account);
        }
    }

    /// @notice Revokes cascading roles from a user.
    /// @param _role The role to be revoked.
    /// @param _account The address of the user.
    function revokeRole(
        bytes32 _role,
        address _account
    ) public override onlyRole(getRoleAdmin(_role)) {
        _revokeRole(_role, _account);
        if (_role == REVIEWER_ROLE) {
            revokeRole(EDITOR_ROLE, _account);
        } else if (_role == EDITOR_ROLE) {
            revokeRole(ADMIN_ROLE, _account);
        } else if (_role == ADMIN_ROLE) {
            revokeRole(DEFAULT_ADMIN_ROLE, _account);
        }
    }

    /// @notice Gets the token URI for the quest chain.
    /// @return uri The token URI.
    function getTokenURI() public view returns (string memory uri) {
        uri = questChainToken.uri(questChainId);
    }

    /// @dev Internal function to submit proof for a quest.
    /// @param _questId The ID of the quest.
    function _submitProof(
        address _quester,
        uint256 _questId
    ) internal validQuest(_questId) questerCanSubmit(_quester, _questId) {
        if (questDetails[_questId].disabled) revert QuestDisabled(_questId);
        if (_questStatus[_msgSender()][_questId] == QuestStatus.pass)
            revert AlreadyPassed(_questId);

        questDetails[_questId].skipReview
            ? _questStatus[_msgSender()][_questId] = QuestStatus.pass
            : _questStatus[_msgSender()][_questId] = QuestStatus.review;
    }

    /// @dev Internal function to review proof for a quest.
    /// @param _quester The address of the quester.
    /// @param _questId The ID of the quest.
    /// @param _success Boolean indicating if the proof was accepted or rejected.
    function _reviewProof(
        address _quester,
        uint256 _questId,
        bool _success
    ) internal validQuest(_questId) {
        if (_questStatus[_quester][_questId] != QuestStatus.review)
            revert QuestNotInReview(_questId);

        _questStatus[_quester][_questId] = _success
            ? QuestStatus.pass
            : QuestStatus.fail;
    }

    /// @dev Internal function to set the token URI.
    /// @param _tokenURI The off-chain token URI.
    function _setTokenURI(string memory _tokenURI) internal {
        questChainToken.setTokenURI(questChainId, _tokenURI);
        emit QuestChainTokenURIUpdated(_tokenURI);
    }
}
