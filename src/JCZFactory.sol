// // SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity ^0.8.13;

// import {JCZ} from "./JCZ.sol";
// import {Auth, Authority} from "solmate/auth/Auth.sol";
// import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

// /// @title Combined Factory
// /// @author
// /// @notice Factory which enables deploying a Vault for any ERC20 token.
// contract Factory is Auth {
//     using Bytes32AddressLib for address;
//     using Bytes32AddressLib for bytes32;

//     modifier onlyOwner() virtual {
//         require(msg.sender == owner, "UNAUTHORIZED");

//         _;
//     }

//     /*///////////////////////////////////////////////////////////////
//                                CONSTRUCTOR
//     //////////////////////////////////////////////////////////////*/

//     /// @notice Creates a Factory.
//     /// @param _owner The owner of the factory.
//     /// @param _authority The Authority of the factory.
//     constructor(address _owner, Authority _authority)
//         Auth(_owner, _authority)
//     {}

//     function deployJCZ(
//         string memory _name,
//         string memory _symbol,
//         address owner,
//         Authority authority
//     ) public onlyOwner returns (JCZ jcz) {}

//     function deployLouBatSei() public returns (Loubatsei loubatsei) {}

//     function setAuthorityModule() public {}
// }
