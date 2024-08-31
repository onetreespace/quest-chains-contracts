// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {ILimiter} from "../interfaces/ILimiter.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MultiToken, Category} from "../libraries/MultiToken.sol";

/// @author @parv3213
contract LimiterTokenFee is ILimiter {
    using MultiToken for MultiToken.Asset;

    struct QuestChainDetails {
        address tokenAddress;
        Category category;
        uint256 nftId;
        address treasuryAddress;
        uint256 feeAmount;
    }

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => QuestChainDetails) public questChainDetails;

    event AddQuestChainDetails(
        address _questChain,
        address _tokenAddress,
        address _treasuryAddress,
        uint256 _feeAmount,
        address _sender
    );

    error Limited();
    error OnlyAdmin();

    function addQuestChainDetails(
        address _questChain,
        address _tokenAddress,
        Category _category,
        uint256 _nftId,
        address _treasuryAddress,
        uint256 _feeAmount
    ) external {
        if (!IAccessControl(_questChain).hasRole(ADMIN_ROLE, msg.sender)) {
            revert OnlyAdmin();
        }
        questChainDetails[_questChain] = QuestChainDetails(
            _tokenAddress,
            _category,
            _nftId,
            _treasuryAddress,
            _feeAmount
        );
        emit AddQuestChainDetails(
            _questChain,
            _tokenAddress,
            _treasuryAddress,
            _feeAmount,
            msg.sender
        );
    }

    function submitProofLimiter(
        address _sender,
        uint256[] calldata /* _questIdList */
    ) external {
        QuestChainDetails memory _details = questChainDetails[msg.sender];

        MultiToken.Asset memory _asset = MultiToken.Asset(
            _details.tokenAddress,
            _details.category,
            _details.feeAmount,
            _details.nftId
        );

        bool success = _asset.transferAssetFrom(
            _sender,
            _details.treasuryAddress
        );
        if (!success) {
            revert Limited();
        }
    }
}
