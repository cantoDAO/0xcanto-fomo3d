// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../JCZ.sol";
import {AuctionQuiz} from "../AuctionQuiz.sol";
import "../Henohenomoheji.sol";

import "../Loubatsei.sol";

import {strings} from "../../lib/solidity-stringutils/src/strings.sol";

interface CheatCodes {
    function deal(address who, uint256 newBalance) external;

    function addr(uint256 privateKey) external returns (address);

    function warp(uint256) external; // Set block.timestamp

    function prank(address) external;

    function startPrank(address) external;

    function prank(address, address) external;

    function startPrank(address, address) external;

    function stopPrank() external;
}

contract AuctionQuizTest is Test {
    AuctionQuiz aq;
    JCZ jcz;
    Henohenomoheji henohenomoheji;

    using strings for *;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address alice = address(0xAAAA); // bob is the author
    address bob = cheats.addr(2);
    address carol = cheats.addr(3);
    address dominic = cheats.addr(4);

    uint256 week = 604800;

    string public q0 = unicode"「粵切字」用粵切字點樣寫？";
    string public a0 = unicode"";
    string public q1 = unicode"きもち寫？";
    string public a1 = unicode"";

    function setUp() public {
        hoax(alice);
        henohenomoheji = new Henohenomoheji();
        aq = new AuctionQuiz();
        jcz = new JCZ("Jyutcitzi", unicode"");
        jcz.setDescriptor(henohenomoheji);
        jcz.setMinter(aq);
    }

    // function test_owner() public {
    //     assertTrue(jcz.owner() == alice);
    // }

    // function test_answering_increases_attempts() public {
    //     // proposing 100 questions
    //     for (uint256 i = 1; i <= 100; i++) {
    //         hoax(alice);
    //         jcz.proposeQuestion(q0, a0);
    //     }

    //     // carol answers the same question (question1) 100 times - all wrong
    //     for (uint256 i = 1; i <= 100; i++) {
    //         (, , , , , , , uint256 attempts) = jcz.questions(i);
    //         assertEq(attempts, 0);
    //         hoax(carol);
    //         jcz.mint(a1);
    //         vm.expectRevert("NOT_MINTED");
    //         jcz.ownerOf(1);
    //     }
    //     (, , , , , , , uint256 attempts_after_answering) = jcz.questions(1);
    //     assertEq(attempts_after_answering, 100);

    //     // carol answers correctly
    //     hoax(carol);
    //     jcz.mint(a0);
    //     assertEq(jcz.ownerOf(1), carol);
    //     (, , , , , , , uint256 attempts_made_after_correctly_answering) = jcz
    //         .questions(1);
    //     assertEq(attempts_made_after_correctly_answering, 101);

    //     // attempts of question 2 is still 0
    //     (, , , , , , , uint256 attempts_of_q2) = jcz.questions(2);
    //     assertEq(attempts_of_q2, 0);
    // }

    // function test_answering_question_resets_GDA() public {
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();
    //     vm.warp(100);

    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     (, , , , , , uint256 question_start_time1, ) = jcz.questions(1);
    //     assertEq(question_start_time1, 100);
    //     vm.warp(200);
    //     hoax(alice);
    //     jcz.proposeQuestion(q1, a1);
    //     (, , , , , , uint256 question_start_time2a, ) = jcz.questions(2);
    //     assertEq(question_start_time2a, 0);

    //     assertGt(1 ether, jcz.getAttemptFee(1));
    //     hoax(carol);
    //     console.log(carol.balance);
    //     jcz.mint{value: 1 ether}(a0);
    //     assertEq(jcz.ownerOf(1), carol);
    //     (, , , , , , uint256 question_start_time2b, ) = jcz.questions(2);
    //     assertEq(question_start_time2b, 200);
    // }

    // // Test attemptFees
    // function test_switch_on_attempt_fees() public {
    //     for (uint256 i = 1; i <= 100; i++) {
    //         assertEq(jcz.getAttemptFee(i), 0);
    //     }

    //     assertFalse(jcz.fees_on());
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();
    //     assertTrue(jcz.fees_on());

    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();

    //     assertFalse(jcz.fees_on());
    // }

    // function test_getInitialPrice() public {
    //     assertFalse(jcz.fees_on());
    //     assertEq(jcz.getInitialPrice(), 0);
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();
    //     assertTrue(jcz.fees_on());
    //     assertEq(jcz.getInitialPrice(), 1 ether);
    //     // 60 seconds after passing 5 weeks (time of deployment is 1 second)
    //     vm.warp(5 weeks + 60);
    //     assertEq(jcz.getInitialPrice(), 10 ether);
    //     vm.warp(20 weeks + 60);
    //     assertEq(jcz.getInitialPrice(), 20 ether);
    //     vm.warp(50 weeks + 60);
    //     assertEq(jcz.getInitialPrice(), 25 ether);
    //     vm.warp(100 weeks + 60);
    //     assertEq(jcz.getInitialPrice(), 50 ether);
    //     vm.warp(150 weeks + 60);
    //     assertEq(jcz.getInitialPrice(), 100 ether);
    //     vm.warp(200 weeks + 60);
    //     assertEq(jcz.getInitialPrice(), 1000 ether);
    // }

    // function test_fees_for_far_off_dates() public {
    //     assertFalse(jcz.fees_on());
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();
    //     assertTrue(jcz.fees_on());

    //     vm.warp(500 weeks);
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     assertGt(jcz.getAttemptFee(1), 100 ether);
    //     assertEq(1000 ether, jcz.getAttemptFee(1));
    //     // decay begins
    //     vm.warp(500 weeks + 10);
    //     assertGt(1000 ether, jcz.getAttemptFee(1));
    // }

    // function test_refund() public {
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();

    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     assertEq(jcz.getAttemptFee(1), 1 ether);
    //     hoax(carol, 10 ether);

    //     jcz.mint{value: 4 ether}(a1);
    //     assertEq(carol.balance, 9 ether);
    // }

    // function test_attempts_spike_attemptFees() public {
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     assertEq(jcz.getAttemptFee(1), 1 ether);
    //     uint256 attemptFee;
    //     for (uint256 i = 1; i <= 20; i++) {
    //         console.log("the attempt fee is:", jcz.getAttemptFee(1));
    //         hoax(carol, 1000000 ether);
    //         jcz.mint{value: 1000000 ether}(a1);
    //         assertGt(jcz.getAttemptFee(1), attemptFee);
    //         attemptFee = jcz.getAttemptFee(1);
    //     }
    // }

    // // Test Drawing functions

    // function testDraw() public view {
    //     console.log(jcz.draw(0));
    //     // console.log(1);
    //     // console.log(jcz.draw(1));
    //     // console.log(200);
    //     // console.log(jcz.draw(200));
    //     // console.log(200000);
    //     // console.log(jcz.draw(200000));
    //     // console.log(jcz.draw(7281000));
    // }

    // // Test minting and Q&A functions

    // function test_propose_question_increases_question_id() public {
    //     uint256 d = 4;
    //     assertEq(jcz.questions_supplied(), 0);
    //     for (uint256 i = 1; i <= d; i++) {
    //         console.log("Question", jcz.questions_supplied());
    //         hoax(alice);
    //         jcz.proposeQuestion(q0, a0);

    //         assertTrue(jcz.questionExists(jcz.questions_supplied()));
    //         assertEq(jcz.questions_supplied(), i);

    //         (
    //             uint256 id,
    //             address proposer,
    //             string memory question,
    //             bytes32 hashedAnswer,
    //             bool jyutcitzi,
    //             string memory answer,
    //             uint256 question_start_time,

    //         ) = jcz.questions(i);
    //         console.log(question);
    //         console.log(i);
    //         console.log("Answer is empty:", answer.toSlice().empty());
    //         console.logBytes32(hashedAnswer);
    //     }
    // }

    // function test_propose_question_does_not_increase_questions_exhausted()
    //     public
    // {
    //     uint256 d = 100;
    //     assertEq(jcz.questions_supplied(), 0);
    //     for (uint256 i = 1; i <= d; i++) {
    //         hoax(alice);
    //         jcz.proposeQuestion(q0, a0);
    //         assertEq(jcz.questions_supplied(), i);
    //         assertTrue(jcz.questionExists(jcz.questions_supplied()));

    //         assertEq(jcz.questions_exhausted(), 0);

    //         console.log("q exhausted:", jcz.questions_exhausted());
    //     }
    // }

    // function test_can_answer_question() public {
    //     uint256 d = 4;
    //     assertEq(jcz.questions_supplied(), 0);

    //     for (uint256 i = 1; i < d; i++) {
    //         hoax(alice);
    //         jcz.proposeQuestion(q0, a0);

    //         assertEq(jcz.questions_supplied(), i);
    //         assertTrue(jcz.questionExists(jcz.questions_supplied()));

    //         assertFalse(jcz._isAnswered(i));

    //         hoax(carol);
    //         jcz.mint(a0);

    //         console.log("after mint, answered?", jcz._isAnswered(i));
    //         assertTrue(jcz._isAnswered(i));
    //         assertTrue(jcz.ownerOf(i) == carol);
    //     }
    // }

    // function testSetQuestions() public {
    //     console.log("before question proposal");
    //     console.log("q supplied", "total supply", "q exhausted");
    //     console.log(
    //         jcz.questions_supplied(),
    //         jcz.totalSupply(),
    //         jcz.questions_exhausted()
    //     );

    //     assertTrue(jcz.questions_supplied() == 0);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);

    //     // // Question 1
    //     // // Proposing question 1
    //     hoax(alice);
    //     bool proposed0 = jcz.proposeQuestion(q0, a0);

    //     console.log("after question proposal");
    //     console.log("q supplied", "total supply", "q exhausted");
    //     console.log(
    //         jcz.questions_supplied(),
    //         jcz.totalSupply(),
    //         jcz.questions_exhausted()
    //     );
    //     assertTrue(jcz.questions_supplied() == 1);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);

    //     hoax(carol);
    //     jcz.mint(a0);

    //     console.log("q supplied", "total supply", "q exhausted");
    //     console.log(
    //         jcz.questions_supplied(),
    //         jcz.totalSupply(),
    //         jcz.questions_exhausted()
    //     );

    //     assertTrue(jcz.questions_supplied() == 1);
    //     assertTrue(jcz.totalSupply() == 1);
    //     assertTrue(jcz.questions_exhausted() == 1);

    //     // // // question 2
    //     hoax(alice);
    //     bool proposed1 = jcz.proposeQuestion("YOUR MUM", a0);
    //     console.log(proposed1);

    //     (
    //         uint256 id,
    //         address proposer,
    //         string memory question,
    //         bytes32 hashedAnswer,
    //         bool jyutcitzi,
    //         string memory answer,
    //         uint256 question_start_time,

    //     ) = jcz.questions(jcz.questions_exhausted());
    //     console.log(question);
    //     console.log(question.toSlice().empty());

    //     hoax(carol);
    //     jcz.mint(a0);

    //     console.log("q supplied", "total supply", "q exhausted");
    //     console.log(
    //         jcz.questions_supplied(),
    //         jcz.totalSupply(),
    //         jcz.questions_exhausted()
    //     );
    //     assertTrue(jcz.questions_supplied() == 2);
    //     assertTrue(jcz.totalSupply() == 2);
    //     assertTrue(jcz.questions_exhausted() == 2);
    // }

    // function test_n_questions() public {
    //     console.log("before question proposal");
    //     console.log("q supplied", "total supply", "q exhausted");
    //     console.log(
    //         jcz.questions_supplied(),
    //         jcz.totalSupply(),
    //         jcz.questions_exhausted()
    //     );

    //     assertTrue(jcz.questions_supplied() == 0);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);

    //     // Question 1
    //     // Proposing question 1
    //     for (uint256 i = 1; i <= 10; i++) {
    //         hoax(alice);
    //         bool proposed = jcz.proposeQuestion(q0, a0);

    //         console.log("after question proposal");
    //         console.log("q supplied", "total supply", "q exhausted");
    //         console.log(
    //             jcz.questions_supplied(),
    //             jcz.totalSupply(),
    //             jcz.questions_exhausted()
    //         );
    //         assertTrue(jcz.questions_supplied() == i);
    //         assertTrue(jcz.totalSupply() == i - 1);
    //         assertTrue(jcz.questions_exhausted() == i - 1);

    //         hoax(bob);
    //         jcz.mint(a0);

    //         assertTrue(jcz.questions_supplied() == i);
    //         assertTrue(jcz.totalSupply() == i);
    //         assertTrue(jcz.questions_exhausted() == i);
    //     }
    // }

    // function test_virgin_question_proposal_starts_timer() public {
    //     uint256 start_time = 13;

    //     assertTrue(jcz.questions_supplied() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     vm.warp(start_time);
    //     assertTrue(block.timestamp == start_time);
    //     (, , , , , , uint256 question_start_time_before_proposal, ) = jcz
    //         .questions(1);
    //     assertTrue(question_start_time_before_proposal == 0);

    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     (, , , , , , uint256 question_start_time_after_proposal, ) = jcz
    //         .questions(1);
    //     assertTrue(question_start_time_after_proposal == start_time);
    // }

    // function test_cur_q_expired_next_q_existent() public {
    //     assertTrue(jcz.questions_supplied() == 0);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     vm.warp(2);
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     hoax(alice);
    //     jcz.proposeQuestion(q1, a1);
    //     assertTrue(jcz.questions_supplied() == 2);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     assertFalse(jcz.isExpired(1));
    //     vm.warp(2 + 604800 + 10000);
    //     console.log(block.timestamp);
    //     assertTrue(jcz.isExpired(1));
    //     assertFalse(jcz.isExpired(2));
    //     hoax(carol);
    //     jcz.mint(a1);

    //     assertTrue(jcz.ownerOf(1) == carol);

    //     assertTrue(jcz.tokenId_to_question(1) == 2);
    // }

    // function test_cur_q_expired_next_q_nonexistent() public {
    //     assertTrue(jcz.questions_supplied() == 0);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     vm.warp(2);
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);

    //     assertTrue(jcz.questions_supplied() == 1);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     assertFalse(jcz.isExpired(1));
    //     vm.warp(2 + 604800 + 10000);
    //     console.log(block.timestamp);
    //     assertTrue(jcz.isExpired(1));
    //     assertFalse(jcz.questionExists(2));
    //     // assertFalse(jcz.isExpired(2));
    //     hoax(carol);
    //     vm.expectRevert("NO QUESTION RN");
    //     jcz.mint(a0);
    // }

    // function test_cur_q_not_expired_but_answered_next_q_existent() public {
    //     vm.warp(2);
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);
    //     hoax(alice);
    //     jcz.proposeQuestion(q1, a1);
    //     assertTrue(jcz.questions_supplied() == 2);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     assertFalse(jcz.isExpired(1));
    //     assertFalse(jcz.isExpired(2));
    //     assertTrue(jcz.questionExists(1));
    //     assertTrue(jcz.questionExists(2));

    //     hoax(carol);
    //     jcz.mint(a0);
    //     assertTrue(jcz.ownerOf(1) == carol);
    //     hoax(dominic);
    //     jcz.mint(a0);
    //     vm.expectRevert("NOT_MINTED");
    //     assertFalse(jcz.ownerOf(2) == dominic);
    // }

    // function test_cur_q_not_expired_but_answered_next_q_nonexistent() public {
    //     vm.warp(2);
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);

    //     assertTrue(jcz.questions_supplied() == 1);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     assertFalse(jcz.isExpired(1));

    //     assertTrue(jcz.questionExists(1));
    //     assertFalse(jcz.questionExists(2));

    //     hoax(bob);
    //     jcz.mint(a0);
    //     assertTrue(jcz.ownerOf(1) == bob);
    //     hoax(carol);
    //     vm.expectRevert("NO QUESTION RN");
    //     jcz.mint(a0);
    // }

    // function test_mints_require_payment() public {
    //     vm.warp(2);
    //     hoax(alice);
    //     jcz.proposeQuestion(q0, a0);

    //     assertTrue(jcz.questions_supplied() == 1);
    //     assertTrue(jcz.totalSupply() == 0);
    //     assertTrue(jcz.questions_exhausted() == 0);
    //     assertFalse(jcz.isExpired(1));

    //     assertTrue(jcz.questionExists(1));
    //     assertFalse(jcz.questionExists(2));

    //     hoax(carol);
    //     jcz.mint(a0);
    //     assertTrue(jcz.ownerOf(1) == carol);
    //     hoax(dominic);
    //     vm.expectRevert("NO QUESTION RN");
    //     jcz.mint(a0);
    // }

    // function deploy_loubatsei() public {
    //     hoax(alice);
    //     loubatsei = new Loubatsei("Loubatsei", "LBS", 100, address(jcz));
    // }

    // function test_set_loubatsei() public {
    //     deploy_loubatsei();

    //     hoax(bob);
    //     vm.expectRevert();
    //     jcz.proposeQuestion(q1, a1);
    //     hoax(alice);
    //     jcz.setLoubatsei(address(loubatsei));
    //     hoax(bob);
    //     uint256 totalSupply = loubatsei.mint{value: 1 ether}(bob);
    //     console.log(totalSupply);
    //     console.log(loubatsei.ownerOf(1));
    //     assertTrue(loubatsei.isLoubatsei(bob));
    //     hoax(bob);
    //     jcz.proposeQuestion(q1, a1);
    // }

    // function test_withdraw_share() public {
    //     // alice proposes 10 questions
    //     for (uint256 i = 1; i <= 10; i++) {
    //         hoax(alice);
    //         jcz.proposeQuestion(q0, a0);
    //     }

    //     assertFalse(jcz.fees_on());
    //     hoax(alice);
    //     jcz.switch_on_attempt_fees();
    //     assertTrue(jcz.fees_on());
    //     // Question 1
    //     for (uint256 i = 1; i <= 10; i++) {
    //         hoax(bob);
    //         jcz.mint{value: 100000000000 ether}("bad answer");
    //     }
    //     hoax(bob);
    //     jcz.mint{value: 100000000000 ether}(a0);
    //     assertTrue(jcz.ownerOf(1) == bob);
    //     // Because the first minter doesn't earn anything
    //     assertEq(jcz.tokenId_to_balance(1), 0);

    //     // On the other hand the treasury should be filled with ether
    //     console.log("the treasury balance is:", address(jcz).balance);

    //     // Question 2

    //     for (uint256 i = 1; i <= 10; i++) {
    //         hoax(carol);
    //         jcz.mint{value: 100000000000 ether}("bad answer");
    //     }
    //     hoax(carol);
    //     jcz.mint{value: 100000000000 ether}(a0);
    //     assertTrue(jcz.ownerOf(2) == carol);
    //     assertGt(jcz.tokenId_to_balance(1), 0);
    //     console.log("the treasury balance is:", address(jcz).balance);
    //     console.log(
    //         "Token 1's withdrawable balance is:",
    //         jcz.tokenId_to_balance(1)
    //     );

    //     // // Question 3

    //     for (uint256 i = 1; i <= 10; i++) {
    //         hoax(dominic);
    //         jcz.mint{value: 100000000000 ether}("bad answer");
    //     }
    //     hoax(dominic);
    //     jcz.mint{value: 100000000000 ether}(a0);
    //     assertGt(jcz.tokenId_to_balance(1), 0);
    //     console.log("the treasury balance is:", address(jcz).balance);
    //     console.log(
    //         "Token 1's withdrawable balance is:",
    //         jcz.tokenId_to_balance(1)
    //     );
    //     console.log(
    //         "Token 2's withdrawable balance is:",
    //         jcz.tokenId_to_balance(2)
    //     );
    //     console.log(
    //         "Token 3's withdrawable balance is:",
    //         jcz.tokenId_to_balance(3)
    //     );
    //     assertTrue(
    //         jcz.totalOwed() ==
    //             jcz.tokenId_to_balance(1) +
    //                 jcz.tokenId_to_balance(2) +
    //                 jcz.tokenId_to_balance(3)
    //     );
    //     console.log("the withdrawable balance is:", jcz.withdrawable());
    //     assertTrue(
    //         jcz.withdrawable() + jcz.totalOwed() == address(jcz).balance
    //     );

    //     // // Carol cannot withdraw Bob's share
    //     vm.expectRevert();
    //     hoax(carol);
    //     uint256 carol_share = jcz.withdrawShare(1);

    //     uint256 bob_balance = bob.balance;

    //     console.log("bob's balance:", bob_balance);
    //     uint256 bob_withdrawable_balance = jcz.tokenId_to_balance(1);
    //     hoax(bob);
    //     uint256 bob_share = jcz.withdrawShare(1);

    //     assertEq(bob_withdrawable_balance, bob_share);

    //     // // after withdrawing, bob's share should be 0
    //     uint256 bob_withdrawable_balance_after_withdrawal = jcz
    //         .tokenId_to_balance(1);
    //     // hoax(bob);
    //     assertEq(bob_withdrawable_balance_after_withdrawal, 0);
    //     hoax(bob);
    //     vm.expectRevert();
    //     jcz.withdrawShare(1);

    //     // suppose someone starts answering questions again
    //     for (uint256 i = 1; i <= 10; i++) {
    //         hoax(dominic);
    //         jcz.mint{value: 100000000000 ether}("bad answer");
    //     }
    //     uint256 bob_withdrawable_balance_after_another_series_of_answering = jcz
    //         .tokenId_to_balance(1);
    //     assertGt(bob_withdrawable_balance_after_another_series_of_answering, 0);
    //     console.log(
    //         "bob's withdrawable balance after another series of answering:",
    //         bob_withdrawable_balance_after_another_series_of_answering
    //     );
    // }
}
