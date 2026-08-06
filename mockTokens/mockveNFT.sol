// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockveNFT is ERC721 {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }
    uint256 private _nextTokenId;

    constructor() ERC721("Mock veNFT", "MVNFT") {}

    function mint(address to) external returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function locked(uint256 id) external view returns (LockedBalance memory) {
        return
            LockedBalance({
                amount: int128(100 ether), // A dummy amount of underlying locked tokens
                end: block.timestamp + 365 days // A dummy lock expiration far in the future
            });
    }
}
