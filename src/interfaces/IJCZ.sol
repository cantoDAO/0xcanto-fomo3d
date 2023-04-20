// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IJCZ {
    function totalSupply() external view returns (uint256);

    // function setDescriptor(Henohenomoheji _henohenomoheji) external;

    // function setMinter(AuctionQuiz _auctionQuiz) external;

    function mint() external returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function burn(uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 id) external;

    function ownerOf(uint256 tokenId) external returns (address owner);
}
