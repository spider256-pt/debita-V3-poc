//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {auctionFactoryDebita} from "@contracts/auctions/AuctionFactory.sol";
import {Script} from "forge-std/Script.sol";

contract DeployAuctionFactory is Script {
    auctionFactoryDebita aDebita;

    function run() external returns (auctionFactoryDebita) {
        vm.startBroadcast();
        aDebita = new auctionFactoryDebita();
        vm.stopBroadcast();
        return aDebita;
    }
}
