// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// import {IJCZ} from "./IJyutctizi.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {strings} from "../lib/solidity-stringutils/src/strings.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract Loubatsei is ERC721, Authority {
    using strings for *;
    uint256 public maxSupply;
    uint256 public totalSupply;
    address jczContractAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _jczContractAddress
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        jczContractAddress = _jczContractAddress;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return (unicode"老不死");
    }

    function mint(address receipient)
        public
        payable
        returns (
            // nonReentrant
            uint256
        )
    {
        totalSupply++;
        uint256 id = totalSupply;
        // console.log(id);
        // tokenId_to_question[id] = questions_exhausted;
        _mint(receipient, id);
        return totalSupply;
    }

    /// @notice Checks if user has any loubatsei tokens, returns true if they do
    /// @param user Address of user that is checked.
    function isLoubatsei(address user) public view returns (bool) {
        if (balanceOf(user) == 0) {
            return false;
        }

        unchecked {
            for (uint256 i = 1; i <= totalSupply; i++) {
                if (ownerOf(i) == user) {
                    return (true);
                }
            }
        }

        // Returns false if none of the tokens owned are within expiry date.
        return false;
    }

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool) {
        if (target == jczContractAddress) {
            return (isLoubatsei(user) &&
                functionSig ==
                bytes4(
                    abi.encodeWithSignature("proposeQuestion(string,string)")
                ));
        }
    }
}
