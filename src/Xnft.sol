// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Xnft is ERC721 {
    uint256 public nextTokenId;
    address public owner;

    constructor() ERC721("XNFT", "XNFT") {
        owner = msg.sender;
    }

    function mint(address to) external {
        require(msg.sender == owner, "only admin can mint");
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
}
