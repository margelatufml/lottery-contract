//Lottery

//Enter the lottery(paying some amount)
//Pick a random winner
//Winner to be selected every x minutes->completely automate
//Chainlink Oracle

//SPDX-License-Identifier:MIT

pragma solidity >=0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error lottery__NotEnoughtETHEntered();
error lottery_TransferFailed();
error lottery_NotOpen();
error lottery_UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);

/**
 * @title A simple lotytery contract
 * @author Air_trader
 * @notice This is a contract for a lottery website
 * @dev This implements ChainlinkVRF adn Keepers
 */

contract lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /**Type declarations*/
    enum LotteryState {
        OPEN,
        CALCULATING
    } //uint256 0=OPEN ,1=CALCULATING
    /*State variables*/
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscribtionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackgasLimit;
    uint32 private constant NUM_WORDS = 1;

    //Lottery Variables
    address private s_recentWinner;
    LotteryState private s_lotterystate;
    uint256 private s_lastTimeStamp;
    uint256 private s_interval;
    /*Events*/
    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vfrCoordinatorV2, //contract
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscribtionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vfrCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vfrCoordinatorV2);
        i_gasLane = gasLane;
        i_subscribtionId = subscribtionId;
        i_callbackgasLimit = callbackGasLimit;
        s_lotterystate = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_interval = interval;
    }

    function enterlottery() public payable {
        //require msg.value>i_entranceFee
        if (msg.value < i_entranceFee) {
            revert lottery__NotEnoughtETHEntered();
        }
        s_players.push(payable(msg.sender));
        //Events
        emit LotteryEnter(msg.sender);
        if (s_lotterystate != LotteryState.OPEN) {
            revert lottery_NotOpen();
        }
    }

    /**
     * @dev This is a function that take thar "UpkeepNeede" to return true
     * The folowing should be true in order to return true:
     * 1.Out time interval should have passed
     * 2.The lottery shold have at least 1 player, and have some ETH
     * 3.Our subsribtion should be founded with LINK
     * 4.Lottery should be in open state
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool isOpen = (LotteryState.OPEN == s_lotterystate);
        //block.timestamp- last block timestamp > interval
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > s_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert lottery_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotterystate)
            );
        }
        s_lotterystate = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscribtionId,
            REQUEST_CONFIRMATIONS,
            i_callbackgasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    //This will send the money to the winner
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotterystate = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool succes, ) = recentWinner.call{value: address(this).balance}("");
        //require(succes)
        if (!succes) {
            revert lottery_TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function getEtraceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotterystate;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public view returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return s_interval;
    }
}
