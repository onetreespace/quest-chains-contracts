// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {ILimiter} from "../interfaces/ILimiter.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MultiToken, Category} from "../libraries/MultiToken.sol";

/// @author @parv3213
contract LimiterTokenGated is ILimiter {
    using MultiToken for MultiToken.Asset;

    struct QuestChainDetails {
        address tokenAddress;
        Category category;
        uint256 nftId;
        uint256 minTokenBalance;
    }

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => QuestChainDetails) public questChainDetails;

    event AddQuestChainDetails(
        address _questChain,
        address _tokenAddress,
        uint256 _minBalance,
        address _sender
    );

    error OnlyAdmin();
    error Limited();

    function addQuestChainDetails(
        address _questChain,
        address _tokenAddress,
        Category _category,
        uint256 _nftId,
        uint256 _minBalance
    ) external {
        if (!IAccessControl(_questChain).hasRole(ADMIN_ROLE, msg.sender)) {
            revert OnlyAdmin();
        }
        questChainDetails[_questChain] = QuestChainDetails(
            _tokenAddress,
            _category,
            _nftId,
            _minBalance
        );
        emit AddQuestChainDetails(
            _questChain,
            _tokenAddress,
            _minBalance,
            msg.sender
        );
    }

    function submitProofLimiter(
        address _sender,
        uint256[] calldata /* _questIdList */
    ) external view {
        QuestChainDetails memory _details = questChainDetails[msg.sender];

        if (
            MultiToken
                .Asset(
                    _details.tokenAddress,
                    _details.category,
                    0,
                    _details.nftId
                )
                .balanceOf(_sender) < _details.minTokenBalance
        ) {
            revert Limited();
        }
    }
}
