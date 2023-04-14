// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;
// import {Authority} from "solmate/auth/Auth.sol";

// import {Loubatsei} from "./Loubatsei.sol";
// import {JCZ} from "./JCZ.sol";

// contract JCZAuthorityModule is Authority {
//     Loubatsei public loubatsei;
//     JCZ public jcz;

//     address public owner;

//     constructor(
//         address _owner,
//         JCZ _jcz,
//         Loubatsei _loubatsei
//     ) {
//         owner = _owner;
//         jcz = _jcz;
//         loubatsei = _loubatsei;
//     }

//     event JCZAddressUpdated(JCZ jcz);
//     event LoubatseiAddressUpdated(Loubatsei loubatsei);

//     bool jczAddressSet;
//     bool loubatseiAddressSet;

//     function user_is_loubatsei(address _user) public view returns (bool) {
//         Loubatsei lbs = loubatsei;
//         bool isLoubatsei = lbs.isLoubatsei(_user);
//         return (isLoubatsei);
//     }

//     function canCall(
//         address user,
//         address target,
//         bytes4 functionSig
//     ) external view returns (bool) {
//         if (target == address(jcz)) {
//             return (user_is_loubatsei(user) &&
//                 functionSig ==
//                 bytes4(
//                     abi.encodeWithSignature("proposeQuestion(string,string)")
//                 ));
//         }
//     }
// }
