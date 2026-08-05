//SPDX-License-Identifier: MIT;

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {
    DBOImplementation
} from "@contracts/DebitaBorrowOffer-Implementation.sol";
import {DBOFactory} from "@contracts/DebitaBorrowOffer-Factory.sol";
import {
    DeployBorrowerScript
} from "../../script/poc/DeployDebitaBorrower.s.sol";

contract TestDebitaBorrower is Test {
    DBOImplementation dImplem;
    DBOFactory dFactory;
    DeployBorrowerScript deployer;

    function setUp() public {
        //Deployment for Debita Factory and Implementaation
        deployer = new DeployBorrowerScript();
        (dFactory, dImplem) = deployer.run();
    }
}
