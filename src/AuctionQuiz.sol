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
import {IJCZ} from "./interfaces/IJCZ.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract AuctionQuiz is Auth, ReentrancyGuard {
    using strings for *;
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    constructor(
        address _weth,
        address _jcz,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint256 _minBidIncrementPercentage,
        uint256 _duration
    ) Auth(msg.sender, Authority(address(0))) {
        weth = _weth;
        jcz = _jcz;

        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    address public jcz;
    address public weth;

    bool public fees_on;
    uint256 public questions_supplied;
    uint256 public questions_exhausted;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint256) public tokenId_to_balance;
    mapping(uint256 => Question) public qid_to_question;

    struct Question {
        // Question data
        // ID for the question
        uint256 qid;
        // Proposer of the
        address proposer;
        // The question itself;
        string question;
        // The answer, hashed
        bytes32 hashedAnswer;
        // Whether the question is legitimately about jyutcitzi
        bool isJcz;
        // The answer to the Question
        string answer;
    }

    struct Auction {
        uint256 qid;
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
    uint256 public minBidIncrementPercentage;

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
        initialAttemptFee = int256(_initialAttemptFee);
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

    bool public auctionActive;

    uint256 public splitable;

    mapping(uint256 => bool) public tokenId_to_active;

    function splitFees() internal {
        // Get the count of active tokenIds
        uint256 activeTokenCount = 0;
        for (uint256 i = 0; i < IJCZ(jcz).totalSupply(); i++) {
            if (tokenId_to_active[i]) {
                activeTokenCount++;
            }
        }

        // Calculate the share for each active tokenId
        uint256 share = 0;
        if (activeTokenCount > 0) {
            share = splitable / activeTokenCount;
        }

        // Update the balance of each active tokenId
        for (uint256 i = 0; i < IJCZ(jcz).totalSupply(); i++) {
            if (tokenId_to_active[i]) {
                tokenId_to_balance[i] += share;
            }
        }

        // Reset the splitable amount
        splitable = 0;
    }

    function proposeQuestion(
        string memory _q,
        string memory _a
    ) public requiresAuth {
        uint256 current_question = questions_supplied + 1;
        Question memory _question = Question({
            qid: current_question,
            proposer: msg.sender,
            question: _q,
            hashedAnswer: keccak256(abi.encodePacked(_a)),
            isJcz: false,
            answer: ""
        });

        // If the next qid has no question, then d
        if (auctionActive == false) {
            _createAuction();
        }
        // if (questions_supplied == questions_exhausted) {
        //     _createAuction();
        //     console.log("auction created!");
        //     console.log("questions_supplied:", questions_supplied);
        //     console.log("questions_exhausted:", questions_exhausted);
        // }
        questions_supplied++;
        qid_to_question[questions_supplied] = _question;
    }

    function _createAuction() internal {
        uint256 _tokenId = IJCZ(jcz).mint();

        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + duration;

        questions_exhausted++;

        Auction memory _auction = Auction({
            qid: questions_exhausted,
            attempts: 0,
            answered: false,
            tokenId: _tokenId,
            startTime: _startTime,
            endTime: _endTime,
            bidder: payable(0),
            settled: false,
            amount: 0
        });
        auctionActive = true;
        auction = _auction;
        emit AuctionCreated(_tokenId, _startTime, _endTime);
    }

    // }

    event AuctionCreated(uint256 tokenid, uint256 startTime, uint256 endTime);

    function _settleAuction() internal {
        Auction memory _auction = auction;
        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );
        auction.settled = true;
        if (_auction.bidder == address(0)) {
            IJCZ(jcz).burn(_auction.tokenId);
        } else {
            IJCZ(jcz).transferFrom(
                address(this),
                _auction.bidder,
                _auction.tokenId
            );
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(address(this), _auction.amount);
        }
        auctionActive = false;
        splitFees();

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    bool paused;
    event AuctionSettled(uint256 tokenId, address bidder, uint256 amount);

    function _pause() internal whenNotPaused {
        paused = true;
    }

    function _unpause() internal whenPaused {
        paused = false;
    }

    modifier whenPaused() {
        require(paused == true, "Pause: not already paused");
        _;
    }
    modifier whenNotPaused() {
        require(paused == false, "Pause: already paused");
        _;
    }

    /**
     * @notice Settle the current auction, mint a new jcz, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction()
        external
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
    function settleAuction() external whenNotPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Pause the jcz auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the jcz auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    function _answer_is_correct(
        uint256 qid,
        string memory _a
    ) internal returns (bool correct) {
        Question memory _question = qid_to_question[qid];

        if (_question.hashedAnswer == keccak256(abi.encodePacked(_a))) {
            return true;
        } else {
            return false;
        }
    }

    uint256 public claimable;
    uint256 public distributable;
    uint256 public tax; // in bips

    function setTax(int256 _tax) public onlyOwner {
        require(_tax <= 1000000, "too big a tax");
        tax = uint256(_tax);
        emit TaxSet(tax);
    }

    event TaxSet(uint256 _tax);

    event FirstToAnswer(Auction auction, uint256 claimable, address answerer);

    function answerQuestionWithBid(string memory _a) public payable {
        Auction memory _auction = auction;

        uint256 attemptFee = getAttemptFee();
        require(msg.value > attemptFee);

        if (!_answer_is_correct(_auction.qid, _a)) {
            // claimable is the amount claimable by the first person to answer correctly
            claimable = claimable + (msg.value * (1000000 - tax)) / 1000000;
            // distributable is the amount distributable to all JCZ holders
            distributable = distributable + (msg.value * tax) / 100000;
            // console.log((msg.value * tax) / 100000);
        } else {
            require(
                msg.value >= reservePrice,
                "Must send at least reservePrice"
            );
            require(block.timestamp < _auction.endTime, "Auction expired");
            require(
                msg.value >=
                    _auction.amount +
                        ((_auction.amount * minBidIncrementPercentage) /
                            100000),
                "Must send more than last bid by minBidIncrementPercentage amount"
            );
            if (!auction.answered) {
                payable(msg.sender).call{value: claimable}("");
                claimable = 0;
                emit FirstToAnswer(auction, claimable, msg.sender);
            }
            address payable lastBidder = _auction.bidder;
            // Refund the last bidder, if applicable
            if (lastBidder != address(0)) {
                _safeTransferETHWithFallback(
                    lastBidder,
                    _auction.amount + msg.value / 1000
                );
            }
            auction.amount = msg.value - (msg.value / 1000);
            auction.bidder = payable(msg.sender);
            // console.log("look!");
            // Extend the auction if the bid was received within `timeBuffer` of the auction end time
            bool extended = _auction.endTime - block.timestamp < timeBuffer;
            if (extended) {
                auction.endTime = _auction.endTime =
                    block.timestamp +
                    timeBuffer;
            }

            emit AuctionBid(_auction.tokenId, msg.sender, msg.value, extended);

            if (extended) {
                emit AuctionExtended(_auction.tokenId, _auction.endTime);
            }
        }
    }

    event AuctionBid(
        uint256 tokenId,
        address bidder,
        uint256 bid,
        bool extended
    );

    event AuctionExtended(uint256 tokenId, uint256 endTime);

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    fallback() external payable {}

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

        if (IJCZ(jcz).ownerOf(tokenId) != msg.sender) {
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
