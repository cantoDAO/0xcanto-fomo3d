// https://github.com/Arachnid/solidity-stringutils

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";

import {strings} from "../lib/solidity-stringutils/src/strings.sol";

contract Henohenomoheji {
    using strings for *;

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

    /**
     * @title Avatar Drawing
     * @dev Generates a face image for a given token ID
     */
    function draw(uint256 tokenId) public view returns (string memory) {
        // Extract face parts and background color for the token ID
        strings.slice memory face = face(tokenId);
        strings.slice memory ear = ear(tokenId);
        strings.slice memory eyebrows = eyebrows(tokenId);
        strings.slice memory eyes = eyes(tokenId);
        strings.slice memory nose = nose(tokenId);
        strings.slice memory mouth = mouth(tokenId);
        strings.slice memory backgroundColour = backgroundColour(tokenId);
        // Create strings for each face part
        strings.slice memory earString = makeEarString(ear);
        strings.slice memory eyebrowsString = makeEyebrowsString(eyebrows);
        strings.slice memory eyesString = makeEyesString(eyes);
        strings.slice memory noseString = makeNoseString(nose);
        strings.slice memory mouthString = makeMouthString(mouth);

        // Combine face part strings into a basic face string
        strings.slice memory basicFaceString = makeBasicFaceString(
            earString,
            eyebrowsString,
            eyesString,
            noseString,
            mouthString
        );

        // Create a complete face string with face shape and background color
        strings.slice memory completeFace = makeCompleteFace(
            face,
            backgroundColour,
            basicFaceString
        );

        // Wrap the complete face in a canvas with background color
        strings.slice memory drawing = wrapCanvas(
            completeFace,
            backgroundColour
        );

        // Return the final drawing as a string
        return drawing.toString();
    }
}
