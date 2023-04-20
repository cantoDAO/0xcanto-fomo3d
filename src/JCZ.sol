// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";
import {IHenohenomoheji} from "./interfaces/IHenohenomoheji.sol";
import {Henohenomoheji} from "./Henohenomoheji.sol";
import {AuctionQuiz} from "./AuctionQuiz.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract JCZ is ERC721, Auth, ReentrancyGuard {
    uint256 public totalSupply;

    address public henohenomoheji;
    address public minter; // auctionQWuiz

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Auth(msg.sender, Authority(address(0))) {}

    function setDescriptor(address _henohenomoheji) external onlyOwner {
        henohenomoheji = _henohenomoheji;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    function setMinter(address _minter) public {
        minter = _minter;
    }

    function mint() public onlyMinter returns (uint256) {
        totalSupply++;
        uint256 id = totalSupply;
        _mint(msg.sender, id);
        return totalSupply;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory tokenURI = IHenohenomoheji(henohenomoheji).draw(tokenId);
        return tokenURI;
    }

    function burn(uint256 tokenId) public onlyMinter {
        _burn(tokenId);
    }
}
