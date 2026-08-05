//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {
    DBOImplementation
} from "@contracts/DebitaBorrowOffer-Implementation.sol";
import {DBOFactory} from "@contracts/DebitaBorrowOffer-Factory.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployBorrowerScript is Script {
    function run()
        external
        returns (DBOFactory dFactory, DBOImplementation dImplem)
    {
        vm.startBroadcast();
        dImplem = new DBOImplementation();
        dFactory = new DBOFactory(address(dImplem));
        vm.stopBroadcast();
        return (dFactory, dImplem);
    }
}
