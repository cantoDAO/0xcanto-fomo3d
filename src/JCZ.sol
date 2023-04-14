// https://github.com/Arachnid/solidity-stringutils

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
// import {IJCZ} from "./IJyutctizi.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {strings} from "../lib/solidity-stringutils/src/strings.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {SD59x18, sd, ln, div, unwrap, mul} from "@prb/math/SD59x18.sol";

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract JCZ is ERC721, Auth, ReentrancyGuard {
    using strings for *;
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    bool public fees_on;
    uint256 public time_of_deployment;
    uint256 public questions_supplied;
    uint256 public questions_exhausted;
    uint256 public totalSupply;
    mapping(uint256 => QA) public questions;
    mapping(uint256 => uint256) public tokenId_to_question;
    mapping(uint256 => uint256) public tokenId_to_balance;

    struct QA {
        uint256 id;
        address proposer;
        string question;
        bytes32 hashedAnswer;
        bool jcz;
        string answer;
        uint256 question_start_time;
        uint256 attemptsMade;
    }

    error NoEthBalance();
    error NotWithdrawn();
    error UnableToRefund();

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Auth(msg.sender, Authority(address(0))) {
        time_of_deployment = block.timestamp;
        fees_on = false;
    }

    // Setting Authorities
    function setLoubatsei(address loubatsei_address) public onlyOwner {
        setAuthority(Authority(loubatsei_address));
    }

    function getInitialPrice() public view returns (int256 initialPrice) {
        if (!fees_on) {
            return 0;
        } else {
            if (block.timestamp - time_of_deployment > 200 weeks) {
                // return int256(1000);
                return 1000 ether;
            } else if (block.timestamp - time_of_deployment > 150 weeks) {
                // return int256(100);
                return 100 ether;
            } else if (block.timestamp - time_of_deployment > 100 weeks) {
                // return int256(50);
                return 50 ether;
            } else if (block.timestamp - time_of_deployment > 50 weeks) {
                // return int256(25);
                return 25 ether;
            } else if (block.timestamp - time_of_deployment > 20 weeks) {
                // return int256(20);
                return 20 ether;
            } else if (block.timestamp - time_of_deployment > 5 weeks) {
                // return int256(10);
                return 10 ether;
            } else {
                return 1 ether;
            }
        }
    }

    int256 public scaleFactorNum = int256(3e20);
    int256 public scaleFactorDen = int256(2e18);

    SD59x18 limit = sd(int256(133_084258667509499441));
    SD59x18 decayConstant = ln(sd(2e18)).div(sd(int256(7e18 weeks)));

    function getAttemptFee(uint256 qid) public view returns (uint256) {
        int256 question_start_time = int256(questions[qid].question_start_time);

        SD59x18 initialPrice = sd(getInitialPrice());
        SD59x18 timeSinceStart = sd(
            (int256(block.timestamp) - question_start_time) * 1e18
        );

        SD59x18 scaleFactor = sd(3e18).div(sd(2e18)); // How much are you going to scale up the price if someone bought an amount. Should be > 1 but not be too big.

        SD59x18 criticalTime = limit.div(decayConstant);

        SD59x18 attemptsMade = sd(int256(questions[qid].attemptsMade) * 1e18);

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

        // console.log("question start time", uint256(question_start_time));
        // console.log("time since start", uint256(unwrap(timeSinceStart)));
        // console.log("decay constant", uint256(unwrap(decayConstant)));
        // console.log(
        //     "decay constant exponentiated",
        //     uint256(unwrap(decayConstant.exp()))
        // );
        // console.log(
        //     "exponent",
        //     uint256(unwrap(decayConstant.mul(timeSinceStart)))
        // );
        // console.log("ln(2):", uint256(unwrap(ln(sd(2e18)))));
        // console.log("this is the total cost", uint256(totalCost));
        // console.log("this is the 1 ether", uint256(1 ether));

        return (uint256(totalCost));
    }

    function startTimer(uint256 qid, uint256 startTime) public {
        questions[qid].question_start_time = startTime;

        questions[qid].attemptsMade = 0;
        console.log(
            "current question start time",
            questions[qid].question_start_time
        );
        console.log("timer started!");
    }

    function isExpired(uint256 qid) public view returns (bool expired) {
        uint256 question_start_time = questions[qid].question_start_time;
        // console.log(qid, "question_start_time", question_start_time, "HI!");
        expired = false;
        if (question_start_time == 0) {
            return false;
        } else {
            expired = block.timestamp - question_start_time > 1 weeks;
        }
        console.log(qid, "expired?", expired);

        return expired;
    }

    // checks if question of a qid exists
    // used to check if question of cqid and cqid+1 exists
    function questionExists(uint256 qid) public view returns (bool) {
        bool exists = questions[qid].question.toSlice().empty() ? false : true;
        return (exists);
    }

    function _answer_is_correct(
        uint256 qid,
        string memory _a
    ) public returns (bool correct) {
        if (questions[qid].hashedAnswer == keccak256(abi.encodePacked(_a))) {
            return true;
        } else {
            return false;
        }
    }

    function proposeQuestion(
        string memory _q,
        string memory _a
    ) public requiresAuth returns (bool done) {
        uint256 current_question = questions_exhausted + 1;
        if (questions_supplied == 0) {
            startTimer(questions_supplied + 1, block.timestamp);
        }

        if (isExpired(current_question)) {
            console.log("shit head!");
            startTimer(current_question + 1, block.timestamp);
        }
        questions_supplied++;
        questions[questions_supplied].id = questions_supplied;
        questions[questions_supplied].proposer = msg.sender;
        questions[questions_supplied].question = _q;
        questions[questions_supplied].hashedAnswer = keccak256(
            abi.encodePacked(_a)
        );

        questions[questions_supplied].jcz = false;

        bool proposed = questionExists(questions_supplied);
        require(proposed, "not proposed!");
        if (proposed) {
            return proposed;
        }
    }

    function _isAnswered(uint256 cqid) public returns (bool answered) {
        answered = !questions[cqid].answer.toSlice().empty();
        return answered;
    }

    function _answerQuestion(string memory _a) public returns (bool correct) {
        uint256 current_question = questions_exhausted + 1;
        require(questionExists(current_question), "NO QUESTION RN");
        require(
            questions[current_question].answer.toSlice().empty(),
            "ANSWERED!"
        );
        // require(!questions[current_question].expired, "EXPIRED!");

        // console.log("answering question", current_question);

        if (isExpired(current_question)) {
            // console.log(current_question, "is expired!");
            if (questionExists(current_question + 1)) {
                // console.log("next question exists!");
                startTimer(current_question + 1, block.timestamp);
            }
            questions_exhausted++;
            // console.log("answering again!");
            // call this function itself, but it will answer the question of the next questions_exhausted
            return _answerQuestion(_a);
        } else {
            questions[current_question].attemptsMade++;
            bool answer_is_correct = _answer_is_correct(current_question, _a);

            if (answer_is_correct) {
                questions[current_question].answer = _a;
                questions_exhausted++;
                if (questionExists(current_question + 1)) {
                    // console.log("next question exists!");
                    startTimer(current_question + 1, block.timestamp);
                }

                return answer_is_correct;
            }
        }
    }

    function switch_on_attempt_fees() public onlyOwner {
        fees_on = !fees_on;
    }

    function withdrawable() public returns (uint256 withdrawable) {
        uint256 withdrawable = address(this).balance - totalOwed;
        return withdrawable;
    }

    function withdraw() public nonReentrant onlyOwner {
        if (address(this).balance == 0) {
            revert NoEthBalance();
        }
        uint256 withdrawable = withdrawable();
        (bool sent, ) = address(owner).call{value: withdrawable}("");
        if (!sent) {
            revert NotWithdrawn();
        }
    }

    error NotOwner();
    error NoShare();

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

    uint256 public totalOwed;

    function mint(
        string memory a
    ) public payable nonReentrant returns (uint256) {
        uint256 current_question = questions_exhausted + 1;
        uint256 attemptFee = getAttemptFee(current_question);

        require(msg.value >= attemptFee, "INSUFFICIENT ATTEMPT FEE!");

        uint256 refund = (attemptFee == 0 ? 0 : msg.value - attemptFee);

        (bool sent, ) = msg.sender.call{value: refund}("");

        if (!sent) {
            revert UnableToRefund();
        } else {
            if (totalSupply != 0) {
                uint256 split = attemptFee / (totalSupply + 1);
                for (uint256 i = 1; i <= totalSupply; i++) {
                    console.log("adding split for", i);
                    tokenId_to_balance[i] += split;
                    totalOwed += split;
                }
            }
            bool correct = _answerQuestion(a);
            console.log("mint function says", correct);
            if (correct) {
                console.log("CORRECT!");
                totalSupply++;
                uint256 id = totalSupply;

                tokenId_to_question[id] = questions_exhausted;
                _mint(msg.sender, id);
            }
            // total supply - i.e. tokenId, starts from 1. There is no token of tokenid 0.
            return totalSupply;
        }
    }

    function markQuestionAsJCZ(uint256 _questions_supplied) public {
        questions[_questions_supplied].jcz = true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory tokenURI = draw(tokenId);
        return tokenURI;
    }

    // // DRAWING

    function random(string memory input) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal view returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function pluck(
        uint256 tokenId,
        string memory component,
        strings.slice[] memory sourceArray
    ) internal view returns (strings.slice memory) {
        uint256 rand = random(
            string(abi.encodePacked(component, toString(tokenId)))
        );
        strings.slice memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function face(
        uint256 tokenId
    ) internal view returns (strings.slice memory) {
        strings.slice[2] memory faces = [
            // じ
            unicode"<g transform='translate(-3000, 7000)'> <text  x='1' y='1' transform='scale(900, 700)'  font-size='smaller' fill='orange' font-weight='lighter' stroke='#FFFFFF' stroke-width='0.2'>じ</text></g>"
                .toSlice(),
            // し
            unicode"<text  x='1' y='11' transform='scale(10, 700)' textLength='1000'  lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='purple' font-weight='lighter'>し</text>"
                .toSlice()
        ];
        uint256 rand = random(
            string(abi.encodePacked("face", toString(tokenId)))
        );
        strings.slice memory output = faces[rand % faces.length];
        return output;
    }

    function eyebrows(
        uint256 tokenId
    ) internal view returns (strings.slice memory) {
        strings.slice[2] memory eyebrowses = [
            unicode"へ".toSlice(),
            unicode"へへ".toSlice()
        ];

        uint256 rand = random(
            string(abi.encodePacked("eyebrows", toString(tokenId)))
        );
        strings.slice memory output = eyebrowses[rand % eyebrowses.length];
        return output;
    }

    function eyes(
        uint256 tokenId
    ) internal view returns (strings.slice memory) {
        strings.slice[11] memory eyeses = [
            unicode"あ".toSlice(),
            unicode"め".toSlice(),
            unicode"ぬ".toSlice(),
            unicode"る".toSlice(),
            unicode"へ".toSlice(),
            unicode"み".toSlice(),
            unicode"ゐ".toSlice(),
            unicode"べ".toSlice(),
            unicode"ぺ".toSlice(),
            unicode"お".toSlice(),
            unicode"の".toSlice()
        ];
        uint256 rand = random(
            string(abi.encodePacked("eyeses", toString(tokenId)))
        );
        strings.slice memory output = eyeses[rand % eyeses.length];
        return output;
    }

    function nose(
        uint256 tokenId
    ) internal view returns (strings.slice memory) {
        strings.slice[18] memory noses = [
            unicode"も".toSlice(),
            unicode"く".toSlice(),
            unicode"い".toSlice(),
            unicode"て".toSlice(),
            unicode"で".toSlice(),
            unicode"ぐ".toSlice(),
            unicode"と".toSlice(),
            unicode"ど".toSlice(),
            unicode"ん".toSlice(),
            unicode"む".toSlice(),
            unicode"り".toSlice(),
            unicode"を".toSlice(),
            unicode"け".toSlice(),
            unicode"げ".toSlice(),
            unicode"に".toSlice(),
            unicode"𬼂".toSlice(),
            unicode"ふ".toSlice(),
            unicode"ぷ".toSlice()
        ];
        uint256 rand = random(
            string(abi.encodePacked("nose", toString(tokenId)))
        );
        strings.slice memory output = noses[rand % noses.length];
        return output;
    }

    function mouth(
        uint256 tokenId
    ) internal view returns (strings.slice memory) {
        strings.slice[19] memory mouths = [
            unicode"へ".toSlice(),
            unicode"こ".toSlice(),
            unicode"ひ".toSlice(),
            unicode"み".toSlice(),
            unicode"し".toSlice(),
            unicode"わ".toSlice(),
            unicode"う".toSlice(),
            unicode"ゑ".toSlice(),
            unicode"そ".toSlice(),
            unicode"つ".toSlice(),
            unicode"ツ".toSlice(),
            unicode"シ".toSlice(),
            unicode"𬻿".toSlice(),
            unicode"𬼀".toSlice(),
            unicode"ソ".toSlice(),
            unicode"ン".toSlice(),
            unicode"ゝ".toSlice(),
            unicode"〻".toSlice(),
            unicode"こ".toSlice()
        ];
        uint256 rand = random(
            string(abi.encodePacked("mouth", toString(tokenId)))
        );
        strings.slice memory output = mouths[rand % mouths.length];
        return output;
    }

    function ear(uint256 tokenId) internal view returns (strings.slice memory) {
        strings.slice[6] memory ears = [
            unicode"る".toSlice(),
            unicode"ろ".toSlice(),
            unicode"う".toSlice(),
            unicode"𛀚".toSlice(),
            unicode"ゟ".toSlice(),
            unicode"〻".toSlice()
        ];
        uint256 rand = random(
            string(abi.encodePacked("ear", toString(tokenId)))
        );
        strings.slice memory output = ears[rand % ears.length];
        return output;
    }

    function backgroundColour(
        uint256 tokenId
    ) internal view returns (strings.slice memory) {
        strings.slice[8] memory backgroundColours = [
            unicode"#FFFFE0".toSlice(),
            unicode"#F0F8FF".toSlice(),
            unicode"#CAFFE8".toSlice(),
            unicode"#FFE2FE".toSlice(),
            unicode"#DFE1FF".toSlice(),
            unicode"#F3FFDF".toSlice(),
            unicode"#FFE6A9".toSlice(),
            unicode"#FFE0DF".toSlice()
        ];
        uint256 rand = random(
            string(abi.encodePacked("backgroundColours", toString(tokenId)))
        );
        strings.slice memory output = backgroundColours[
            rand % backgroundColours.length
        ];
        return output;
    }

    function makeFaceString(
        strings.slice memory _face,
        strings.slice memory _background_colour
    ) public view returns (strings.slice memory _faceString, bool shi) {
        if (_face.equals(unicode"し".toSlice())) {
            return (
                (
                    // faceshi し
                    (
                        (
                            (
                                unicode"<g transform='translate(-2200, 7000)'><text  x='1' y='1' transform='scale(900, 700)'  font-size='smaller' fill='black' font-weight='lighter' stroke='"
                                    .toSlice()
                            )
                        ).concat(_background_colour).toSlice()
                    )
                        .concat(
                            (
                                unicode"' stroke-width='0.5'>し</text></g>"
                                    .toSlice()
                            )
                        )
                        .toSlice()
                ),
                true
            );
        } else {
            return (
                (
                    // faceji じ
                    (
                        (
                            (
                                unicode"<g transform='translate(-3267, 7000)'><text  x='1' y='1' transform='scale(930, 700)' font-size='smaller' fill='black' font-weight='lighter' stroke='"
                                    .toSlice()
                            ).concat(_background_colour).toSlice()
                        ).concat(
                                unicode"' stroke-width='0.5'>じ</text></g>"
                                    .toSlice()
                            )
                    ).toSlice()
                ),
                false
            );
        }
    }

    function makeEarString(
        strings.slice memory _ear
    ) internal view returns (strings.slice memory _earString) {
        return (
            (
                (
                    (
                        unicode"<g transform='translate(6700, 4600)'><text  x='1' y='1'  transform='scale(180)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>"
                            .toSlice()
                    ).concat(_ear).toSlice()
                ).concat(unicode"</text></g>".toSlice())
            ).toSlice()
        );
    }

    function makeEyebrowsString(
        strings.slice memory _eyebrows
    ) internal view returns (strings.slice memory _eyebrowsString) {
        if (_eyebrows.equals(unicode"へ".toSlice())) {
            return (
                unicode"<g transform='translate(1200, 3000)'><text  x='2' y='0'  transform='translate(1000, -200) scale(170)' textLength='2.5em' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>へ</text></g>"
                    .toSlice()
            );
        } else {
            return (
                unicode"<g transform='translate(2400, 2800)'><text  x='1' y='1'  transform='scale(200)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>へ</text></g><g transform='translate(4800, 2800)'>    <text  x='1' y='1'  transform='scale(200)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>へ</text></g>"
                    .toSlice()
            );
        }
    }

    function makeEyesString(
        strings.slice memory _eyes
    ) internal view returns (strings.slice memory _eyesString) {
        return (
            (
                (
                    (
                        (
                            unicode"<g transform='translate(2900, 3620)'><text  x='1' y='1'  transform='scale(120)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>"
                                .toSlice()
                        ).concat(_eyes).toSlice()
                    ).concat(unicode"</text></g>".toSlice()).toSlice()
                ).concat(
                        (
                            (
                                unicode"<g transform='translate(5300, 3620)'><text  x='1' y='1'  transform='scale(120)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>"
                                    .toSlice()
                            ).concat(_eyes).toSlice()
                        ).concat(unicode"</text></g>".toSlice()).toSlice()
                    )
            ).toSlice()
        );
    }

    function makeNoseString(
        strings.slice memory _nose
    ) internal view returns (strings.slice memory _noseString) {
        return (
            (
                (
                    (
                        unicode"<g transform='translate(4000, 5000)'><text  x='1' y='1'  transform='scale(120)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>"
                            .toSlice()
                    ).concat(_nose)
                ).toSlice()
            ).concat(unicode"</text></g>".toSlice()).toSlice()
        );
    }

    function makeMouthString(
        strings.slice memory _mouth
    ) internal view returns (strings.slice memory _mouthString) {
        return (
            (
                (
                    (
                        unicode"<g transform='translate(4000, 7000)'><text  x='1' y='1'  transform='scale(120)' lengthAdjust='spacingAndGlyphs' font-size='smaller' fill='black' font-weight='lighter'>"
                            .toSlice()
                    ).concat(_mouth).toSlice()
                ).concat(unicode"</text></g>".toSlice())
            ).toSlice()
        );
    }

    function makeBasicFaceString(
        strings.slice memory _earsString,
        strings.slice memory _eyebrowsString,
        strings.slice memory _eyesString,
        strings.slice memory _noseString,
        strings.slice memory _mouthString
    ) internal view returns (strings.slice memory _basicFaceString) {
        return (
            (
                (((_earsString).concat(_eyebrowsString)).toSlice()).concat(
                    (
                        (((_eyesString).concat(_noseString)).toSlice()).concat(
                            _mouthString
                        )
                    ).toSlice()
                )
            ).toSlice()
        );
    }

    function makeCompleteFace(
        strings.slice memory _face,
        strings.slice memory _background_colour,
        strings.slice memory _basicFaceString
    ) internal view returns (strings.slice memory completeFace) {
        (strings.slice memory _faceString, bool shi) = makeFaceString(
            _face,
            _background_colour
        );

        if (shi) {
            // faceshi し
            return ((_faceString.concat(_basicFaceString)).toSlice());
        } else {
            // faceji じ
            return (
                (
                    (
                        (
                            (
                                (
                                    _faceString.concat(
                                        (
                                            unicode"<g  transform='translate(500, 1500) scale(0.83)'>"
                                                .toSlice()
                                        )
                                    )
                                ).toSlice()
                            ).concat(_basicFaceString)
                        ).toSlice()
                    ).concat(unicode"</g>".toSlice())
                ).toSlice()
            );
        }
    }

    function wrapCanvas(
        strings.slice memory _stuff_inside,
        strings.slice memory _background_colour
    ) internal view returns (strings.slice memory drawing) {
        strings.slice memory head = (
            (
                (
                    (
                        (
                            unicode"<svg  xmlns='http://www.w3.org/2000/svg' width='10000' height='10000' style='background-color:"
                                .toSlice()
                        )
                    ).concat(_background_colour)
                ).toSlice()
            ).concat(unicode"'>".toSlice()).toSlice()
        );

        strings.slice memory tail = unicode"</svg>".toSlice();

        return (head.concat((_stuff_inside.concat(tail)).toSlice())).toSlice();
    }

    function draw(uint256 tokenId) public view returns (string memory) {
        strings.slice memory _face = face(tokenId);
        strings.slice memory _ear = ear(tokenId);
        strings.slice memory _eyebrows = eyebrows(tokenId);
        strings.slice memory _eyes = eyes(tokenId);
        strings.slice memory _nose = nose(tokenId);
        strings.slice memory _mouth = mouth(tokenId);
        strings.slice memory _background_colour = backgroundColour(tokenId);
        strings.slice memory _basicFaceString = makeBasicFaceString(
            makeEarString(_ear),
            makeEyebrowsString(_eyebrows),
            makeEyesString(_eyes),
            makeNoseString(_nose),
            makeMouthString(_mouth)
        );
        strings.slice memory completeFace = makeCompleteFace(
            _face,
            _background_colour,
            _basicFaceString
        );
        strings.slice memory drawing = wrapCanvas(
            completeFace,
            _background_colour
        );
        return drawing.toString();
    }
}
