// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Crowdfunding is Ownable {
    // Struct

    struct depositerDetails {
        uint256 amount;
        uint256 transactionId;
    }

    // Variables

    uint256 public goal;
    uint256 public raised;
    uint256 public duration;

    // Custom Errors

    error CampaignInProgress();
    error CampaignExpired();
    error CampaignNotStartedYet();
    error IdNotFound();
    error CampaignGoalReached();
    error CampaignGoalNotReached();
    error InsuffcientAmount();
    error AmountPending();

    // Events

    event CampaignCreated(
        address creator,
        uint256 goal,
        uint256 startTime,
        uint256 duration
    );
    event AmountPledged(
        address pledger,
        uint256 amount,
        uint256 transactionId,
        uint256 time
    );
    event AmountUnPledged(
        address unPledgedBy,
        uint256 amount,
        uint256 transactionId,
        uint256 time
    );
    event AmountWithdrawal(
        address withdrawer,
        address to,
        uint256 amount,
        uint256 time
    );
    event AmountRefunded(
        address to,
        uint256 amount,
        uint256 transactionId,
        uint256 time
    );

    // Mappings

    mapping(address => mapping(uint256 => depositerDetails)) public depositer;
    mapping(address => uint256) public transactionId;

    // Functions

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev createCampaign is to start campaign.
     * contract owner can start the campaign .
     * Requirement:
     * @param _goal- goaled amount
     * @param _duration- campaign duration
     * Emits a {CampaignCreated} event.
     */

    function createCampaign(uint256 _goal, uint256 _duration) public onlyOwner {
        if (block.timestamp > duration) {
            if (raised != 0.000000000000000000) revert AmountPending();
            goal = (_goal / 1) * 10**18;
            duration = block.timestamp + _duration;
            emit CampaignCreated(msg.sender, goal, block.timestamp, duration);
        } else {
            revert CampaignInProgress();
        }
    }

    /**
     * @dev amountPledge is to pledge amount.
     * User will pledge the amount.
     * Requirement: ;
     * Emits a {AmountPledged} event.
     */

    function amountPledge() public payable {
        if (duration == 0) revert CampaignNotStartedYet();
        if (block.timestamp > duration) revert CampaignExpired();
        payable(address(this)).transfer(msg.value);
        transactionId[msg.sender]++;
        depositer[msg.sender][transactionId[msg.sender]] = depositerDetails(
            msg.value,
            transactionId[msg.sender]
        );

        raised += msg.value;
        emit AmountPledged(
            msg.sender,
            msg.value,
            transactionId[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev unPledge is to unpledge amount only during campaign.
     * User who pledged the amount only can unpledge.
     * Requirement:
     * @param _transactionId- pladged amount Id
     * Emits a {AmountUnPledged} event.
     */

    function unPledge(uint256 _transactionId) public payable {
        if (block.timestamp > duration) revert CampaignExpired();
        if (
            depositer[msg.sender][_transactionId].transactionId ==
            _transactionId
        ) {
            if (depositer[msg.sender][_transactionId].amount == 0)
                revert InsuffcientAmount();

            payable(msg.sender).transfer(
                depositer[msg.sender][_transactionId].amount);
            
            depositer[msg.sender][_transactionId].amount = 0;
            raised = raised - depositer[msg.sender][_transactionId].amount;

            emit AmountUnPledged(
                msg.sender,
                depositer[msg.sender][_transactionId].amount,
                _transactionId,
                block.timestamp
            );
        } else {
            revert IdNotFound();
        }
    }

    /**
     * @dev withdraw for amount withdrawal only callable if the campaign expires and the goal reached.
     * Only Owner can withdraw.
     * Requirement:
     * @param _to- address to withdraw
     * Emits a {AmountWithdrawal} event.
     */

    function withdraw(address _to) public onlyOwner {
        if (!(block.timestamp > duration)) revert CampaignInProgress();
        if (raised >= goal) {
            payable(_to).transfer(raised);
            raised = 0;
            emit AmountWithdrawal(msg.sender, _to, raised, block.timestamp);
        } else {
            revert CampaignGoalNotReached();
        }
    }

    /**
     * @dev refund for amount refund to pledgers if goal not reached.
     * Requirement:
     * @param _transactionId- pladged amount Id
     * Emits a {AmountRefunded} event.
     */

    function refund(uint256 _transactionId) public {
        if (!(block.timestamp > duration)) revert CampaignInProgress();
        if (depositer[msg.sender][_transactionId].transactionId !=
            _transactionId)
         revert IdNotFound();
        if (depositer[msg.sender][_transactionId].amount == 0)
            revert InsuffcientAmount();
          

        if (raised < goal) {
            payable(msg.sender).transfer(
                depositer[msg.sender][_transactionId].amount);
            
            depositer[msg.sender][_transactionId].amount = 0;
            raised = 0;

            emit AmountRefunded(
                msg.sender,
                depositer[msg.sender][_transactionId].amount,
                _transactionId,
                block.timestamp
            );
        } else {
            revert CampaignGoalReached();
        }
    }

    /**
     * @dev campaignStatus is to check the current campiagn status.
     * Requirement: ;
     */

    function campaignStatus() public view returns (bool) {
        if (duration == 0) revert CampaignNotStartedYet();
        if (block.timestamp > duration) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @dev goalReached is to check the the goal status.
     * Requirement: ;
     */

    function goalReached() public view returns (bool) {
        if (duration == 0) revert CampaignNotStartedYet();
        if (raised >= goal) {
            return true;
        } else {
            return false;
        }
    }
}
