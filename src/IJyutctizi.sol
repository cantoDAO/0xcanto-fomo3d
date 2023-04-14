// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IJCZ {
    function questionId() external returns (uint256);

    struct QA {
        uint256 id;
        address proposer;
        string question;
        bytes32 hashedAnswer;
        bool jcz;
        bool expired;
        string answer;
    }

    function proposeQuestion(string memory _question, string memory _answer)
        external
        returns (bool done);

    function answerQuestion(string memory _answer)
        external
        returns (bool correct);

    function markQuestionAsJCZ() external;
}
