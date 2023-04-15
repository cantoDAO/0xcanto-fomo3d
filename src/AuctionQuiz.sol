// https://github.com/Arachnid/solidity-stringutils

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {strings} from "../lib/solidity-stringutils/src/strings.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";
import {SD59x18, sd, ln, div, unwrap, mul} from "@prb/math/SD59x18.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {JCZ} from "./JCZ.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuctionQuiz is Auth, ReentrancyGuard {
    using strings for *;
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    constructor(address _weth) Auth(msg.sender, Authority(address(0))) {
        weth = _weth;
    }

    // This needs to be eventually replaced with interfaces
    JCZ public jcz;

    function setJCZ(JCZ _jcz) public {
        jcz = _jcz;
    }

    bool public fees_on;
    uint256 public questions_supplied;
    uint256 public questions_exhausted;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint256) public tokenId_to_balance;

    address public weth;

    struct Auction {
        // Question data
        // ID for the question
        uint256 questionId;
        // Proposer of the
        address proposer;
        // The question itself;
        string question;
        // The answer, hashed
        bytes32 hashedAnswer;
        // Whether the question is legitimately about jyutcitzi
        bool jcz;
        // The answer to the Question
        string answer;
        // Number of attempts
        uint256 attempts;
        // Answered?
        bool answered;
        // Auction data
        uint256 tokenId;
        // The time that the quiz-auction started
        uint256 startTime;
        // The time that the quiz-auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
        // The current highest bid amount
        uint256 amount;
    }

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    Auction public auction; // currently active auction;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    int256 public scaleFactorNum = int256(3e20);
    int256 public scaleFactorDen = int256(2e18);
    int256 public initialAttemptFee;

    SD59x18 limit = sd(int256(133_084258667509499441));
    SD59x18 decayConstant = ln(sd(2e18)).div(sd(int256(1e18 days)));

    event InitialAttemptFeeUpdated(uint256 initialAttemptFee);

    function setInitialAttemptFee(uint256 _initialAttemptFee) public onlyOwner {
        initialAttemptFee = _initialAttemptFee;
        emit InitialAttemptFeeUpdated(_initialAttemptFee);
    }

    function getAttemptFee() public view returns (uint256) {
        Auction memory a = auction;
        int256 attempts = int256(a.attempts);
        int256 startTime = int256(a.startTime);

        SD59x18 initialPrice = sd(initialAttemptFee);
        SD59x18 timeSinceStart = sd(
            (int256(block.timestamp) - startTime) * 1e18
        );
        SD59x18 scaleFactor = sd(3e18).div(sd(2e18)); // How much are you going to scale up the price if someone bought an amount. Should be > 1 but not be too big.
        SD59x18 criticalTime = limit.div(decayConstant);
        SD59x18 attemptsMade = sd(attempts * 1e18);
        SD59x18 n = initialPrice.mul(scaleFactor.pow(attemptsMade));
        SD59x18 decay = (
            unwrap(decayConstant.mul(timeSinceStart)) >= unwrap(limit)
                ? (
                    (limit.floor().exp()).add(sd(int256(block.timestamp))).sub(
                        criticalTime
                    )
                )
                : (decayConstant.mul(timeSinceStart)).exp()
        );

        int256 totalCost = unwrap(n.div(decay));

        return (uint256(totalCost));
    }

    function proposeQuestion(
        string memory _q,
        string memory _a
    ) public requiresAuth {
        uint256 current_question = questions_exhausted + 1;
        Auction memory _auction = auction;
        _auction.questionId = current_question;
        _auction.proposer = msg.sender;
        _auction.question = _q;
        _auction.hashedAnswer = keccak256(abi.encodePacked(_a));

        if (questions_supplied == questions_exhausted) {
            _createAuction();
        }
        questions_supplied++;
    }

    function _createAuction() internal {
        try jcz.mint() returns (uint256 tokenId) {
            auction.tokenId = tokenId;
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction.startTime == startTime;
            auction.endTime = endTime;
            auction.bidder = payable(0);
            auction.settled = false;
            emit AuctionCreated(tokenId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    function _settleAuction() internal {
        Auction memory _auction = auction;
        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );
        auction.settled = true;
        questions_exhausted++;
        if (_auction.bidder == address(0)) {
            jcz.burn(_auction.tokenId);
        } else {
            jcz.transferFrom(address(this), _auction.bidder, _auction.tokenId);
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    bool pause;

    function _pause() internal whenNotPaused {
        pause = true;
    }

    function _unpause() internal whenPaused {
        pause = false;
    }

    modifier whenPaused() {
        require(pause == true, "Pause: not already paused");
        _;
    }
    modifier whenNotPaused() {
        require(pause == false, "Pause: already paused");
        _;
    }

    /**
     * @notice Settle the current auction, mint a new Noun, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction()
        external
        override
        nonReentrant
        whenNotPaused
    {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Pause the jcz auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the jcz auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    function _answer_is_correct(
        uint256 qid,
        string memory _a
    ) internal returns (bool correct) {
        if (questions[qid].hashedAnswer == keccak256(abi.encodePacked(_a))) {
            return true;
        } else {
            return false;
        }
    }

    uint256 public claimable;
    uint256 public distributable;
    uint256 public tax; // in percentage

    function setTax(int256 _tax) public onlyOwner {
        require(_tax <= 1000000, "too big a tax");
        tax = _tax;
        emit TaxSet(_tax);
    }

    event TaxSet(uint256 _tax);

    event FirstToAnswer(Auction auction, uint256 claimable, address answerer);

    function answerQuestionWithBid(string memory _a) public payable {
        Auction memory _auction = auction;

        uint256 attemptFee = getAttemptFee();
        require(msg.value > attemptFee);

        if (!_answer_is_correct(_a)) {
            claimable = claimable + (msg.value) * ((1000000 - tax) / 1000000);
            distributable = (+msg.value * tax) / 100000;
        } else {
            require(
                msg.value >= reservePrice,
                "Must send at least reservePrice"
            );
            require(block.timestamp < _auction.endTime, "Auction expired");
            require(
                msg.value >=
                    _auction.amount +
                        ((_auction.amount * minBidIncrementPercentage) / 100),
                "Must send more than last bid by minBidIncrementPercentage amount"
            );
            if (!answered) {
                payable(msg.sender).call{value: claimable}("");
                claimable = 0;
                emit FirstToAnswer(auction, claimable, msg.sender);
            }
            address payable lastBidder = _auction.bidder;
            // Refund the last bidder, if applicable
            if (lastBidder != address(0)) {
                _safeTransferETHWithFallback(lastBidder, _auction.amount);
            }
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);
            // Extend the auction if the bid was received within `timeBuffer` of the auction end time
            bool extended = _auction.endTime - block.timestamp < timeBuffer;
            if (extended) {
                auction.endTime = _auction.endTime =
                    block.timestamp +
                    timeBuffer;
            }

            emit AuctionBid(_auction.nounId, msg.sender, msg.value, extended);

            if (extended) {
                emit AuctionExtended(_auction.nounId, _auction.endTime);
            }
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(
        address to,
        uint256 value
    ) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    error NotOwner();
    error NoShare();
    error NoEthBalance();
    error NotWithdrawn();

    function withdrawShare(
        uint256 tokenId
    ) public nonReentrant returns (uint256 share) {
        if (address(this).balance == 0) {
            revert NoEthBalance();
        }
        uint256 share = tokenId_to_balance[tokenId];
        if (share == 0) {
            revert NoShare();
        }

        if (this.ownerOf(tokenId) != msg.sender) {
            revert NotOwner();
        } else {
            (bool sent, ) = address(owner).call{value: share}("");
            if (!sent) {
                revert NotWithdrawn();
            } else {
                tokenId_to_balance[tokenId] = 0;
                return (share);
            }
        }
    }
}
