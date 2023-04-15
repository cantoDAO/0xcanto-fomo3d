// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";
import {IHenohenomoheji} from "./interfaces/IHenohenomoheji.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract JCZ is ERC721, Auth, ReentrancyGuard {
    uint256 public totalSupply;

    IHenohenomoheji public henohenomoheji;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Auth(msg.sender, Authority(address(0))) {}

    function setDescriptor(
        IHenohenomoheji _henohenomoheji
    ) external override onlyOwner {
        henohenomoheji = _henohenomoheji;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }
    address public minter;

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
        string memory tokenURI = henohenomoheji.draw(tokenId);
        return tokenURI;
    }
}
