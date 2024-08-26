// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {QuestChainCommons} from "../libraries/QuestChainCommons.sol";
import {IQuestChainToken} from "./IQuestChainToken.sol";
import {IQuestChainFactory} from "./IQuestChainFactory.sol";

/// @notice Represents the possible statuses of a quest.
enum QuestStatus {
    init, // Quest is initialized but not yet reviewed or completed.
    review, // Quest is under review.
    pass, // Quest has been successfully completed.
    fail // Quest has failed.
}

/// @notice Structure for holding quest details.
/// @dev Includes information about whether the quest is paused, optional, or can skip review.
struct QuestDetails {
    // uint256 order; // The order of the quest in the chain.
    // bool assignment; // Indicates if the quest is an assignment.
    // uint256[] requiredQuests; // List of quest IDs required to complete this quest.
    bool disabled; // Indicates if the quest is paused.
    bool optional; // Indicates if the quest is optional.
    bool skipReview; // Indicates if the quest can skip the review process.
}

/// @title IQuestChainFunctions
/// @notice Interface for managing quest chains, including creation, editing, submission, and review of quests.
interface IQuestChainFunctions {
    /// @notice Initializes the quest chain with provided information.
    /// @param _info Struct containing quest chain information such as owners, admins, editors, reviewers, and quests.
    function init(QuestChainCommons.QuestChainInfo calldata _info) external;

    /// @notice Sets the token URI for the quest chain.
    /// @param _tokenURI The off-chain token URI.
    function setTokenURI(string memory _tokenURI) external;

    /// @notice Edits the quest chain details.
    /// @param _details URI of off-chain details for the quest chain.
    function edit(string calldata _details) external;

    /// @notice Creates new quests in the quest chain.
    /// @param _detailsList List of URIs of off-chain details for new quests.
    function createQuests(string[] calldata _detailsList) external;

    /// @notice Edits existing quests in the quest chain.
    /// @param _questIdList List of quest IDs to be edited.
    /// @param _detailsList List of URIs of off-chain details for each quest.
    function editQuests(
        uint256[] calldata _questIdList,
        string[] calldata _detailsList
    ) external;

    /// @notice Configures quests in the quest chain.
    /// @param _questIdList List of quest IDs to be configured.
    /// @param _questDetails List of details for each quest.
    function configureQuests(
        uint256[] calldata _questIdList,
        QuestDetails[] calldata _questDetails
    ) external;

    /// @notice Submits proofs for completing particular quests in the quest chain.
    /// @param _questIdList List of quest IDs for the quest submissions.
    /// @param _proofList List of off-chain proofs for each quest.
    function submitProofs(
        uint256[] calldata _questIdList,
        string[] calldata _proofList
    ) external;

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
    ) external;

    /// @notice Mints an NFT to the sender if they have completed all quests.
    function mintToken() external;

    /// @notice Burns the NFT from the sender.
    function burnToken() external;

    /// @notice Gets the factory of the quest chain.
    /// @return The address of the quest chain factory.
    function questChainFactory() external view returns (IQuestChainFactory);

    /// @notice Gets the token associated with the quest chain.
    /// @return The address of the quest chain token.
    function questChainToken() external view returns (IQuestChainToken);

    /// @notice Gets the identifier for the quest chain.
    /// @return The quest chain ID.
    function questChainId() external view returns (uint256);

    /// @notice Gets the token URI for the quest chain.
    /// @return The off-chain token URI.
    function getTokenURI() external view returns (string memory);

    /// @notice Gets the status of a quest for a specific quester.
    /// @param _quester The address of the quester.
    /// @param _questId The ID of the quest.
    /// @return The status of the quest.
    function questStatus(
        address _quester,
        uint256 _questId
    ) external view returns (QuestStatus);
}

/// @title IQuestChainSignals
/// @notice Interface for QuestChain signals including events and errors.
interface IQuestChainSignals {
    /// @notice Emitted when the QuestChain is initialized.
    /// @param details The off-chain details of the quest chain.
    /// @param quests The list of quests.
    /// @param paused The pause status of the quest chain.
    event QuestChainInit(string details, string[] quests, bool paused);

    /// @notice Emitted when the QuestChain is edited.
    /// @param sender The address of the user who edited the quest chain.
    /// @param details The off-chain details of the edited quest chain.
    event QuestChainEdited(address indexed sender, string details);

    /// @notice Emitted when a limiter is set for the QuestChain.
    /// @param limiterContract The address of the limiter contract.
    event SetLimiter(address limiterContract);

    /// @notice Emitted when new quests are created in the QuestChain.
    /// @param sender The address of the user who created the quests.
    /// @param detailsList The list of off-chain details for the new quests.
    event QuestsCreated(address indexed sender, string[] detailsList);

    /// @notice Emitted when quests are edited in the QuestChain.
    /// @param sender The address of the user who edited the quests.
    /// @param questIdList The list of quest IDs that were edited.
    /// @param detailsList The list of off-chain details for the edited quests.
    event QuestsEdited(
        address indexed sender,
        uint256[] questIdList,
        string[] detailsList
    );

    /// @notice Emitted when quests are configured in the QuestChain.
    /// @param sender The address of the user who configured the quests.
    /// @param questIdList The list of quest IDs that were configured.
    /// @param questDetails The details of the configured quests.
    event ConfiguredQuests(
        address indexed sender,
        uint256[] questIdList,
        QuestDetails[] questDetails
    );

    /// @notice Emitted when proofs are submitted for quests in the QuestChain.
    /// @param sender The address of the user who submitted the proofs.
    /// @param questIdList The list of quest IDs for which proofs were submitted.
    /// @param proofList The list of off-chain proofs for each quest.
    event QuestProofsSubmitted(
        address indexed sender,
        uint256[] questIdList,
        string[] proofList
    );

    /// @notice Emitted when proofs are reviewed for quests in the QuestChain.
    /// @param sender The address of the reviewer.
    /// @param questerList The list of questers whose proofs were reviewed.
    /// @param questIdList The list of quest IDs for which proofs were reviewed.
    /// @param successList The list of booleans indicating whether each proof was accepted or rejected.
    /// @param detailsList The list of off-chain comments for each submission.
    event QuestProofsReviewed(
        address indexed sender,
        address[] questerList,
        uint256[] questIdList,
        bool[] successList,
        string[] detailsList
    );

    /// @notice Emitted when the token URI for the QuestChain is updated.
    /// @param tokenURI The new off-chain token URI.
    event QuestChainTokenURIUpdated(string tokenURI);

    /// @notice Error thrown when the sender is not the factory contract.
    error NotFactory();

    /// @notice Error thrown when a quest is not found.
    /// @param questId The quest ID that was not found.
    error QuestNotFound(uint256 questId);

    /// @notice Error thrown when invalid parameters are provided.
    error InvalidParams();

    /// @notice Error thrown when a quest is paused.
    /// @param questId The paused quest ID.
    error QuestDisabled(uint256 questId);

    /// @notice Error thrown when a quest has already been passed.
    /// @param questId The quest ID that has already been passed.
    error AlreadyPassed(uint256 questId);

    /// @notice Error thrown when a quest is not in review.
    /// @param questId The quest ID that is not in review.
    error QuestNotInReview(uint256 questId);

    /// @notice Error thrown when the quest chain has no owners.
    error NoOwners();

    /// @notice Error thrown when there are no quests found in the quest chain.
    error NoQuestsFound();

    /// @notice Error thrown when the quest chain is incomplete.
    error ChainIncomplete();

    /// @notice Error thrown when there are no successful reviews.
    error NoSuccessfulReview();
}

/// @title IQuestChain
/// @notice Interface for managing quest chains, including creation, editing, submission, and review of quests.
/// @dev This interface defines the core functions and events required for managing quests within a quest chain.
// solhint-disable-next-line no-empty-blocks
interface IQuestChain is IQuestChainFunctions, IQuestChainSignals {

}
