//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {
    DBOImplementation
} from "@contracts/DebitaBorrowOffer-Implementation.sol";
import {DBOFactory} from "@contracts/DebitaBorrowOffer-Factory.sol";
import {
    DeployBorrowerScript
} from "../../script/poc/DeployDebitaBorrower.s.sol";

import {MockveNFT} from "../../mockTokens/mockveNFT.sol";
import {MockERC20} from "../../mockTokens/mockERC20.sol";
import {
    veNFTEqualizer
} from "@contracts/Non-Fungible-Receipts/veNFTS/Equalizer/Receipt-veNFT.sol";

import {DebitaV3Aggregator} from "@contracts/DebitaV3Aggregator.sol";

import {DLOFactory} from "@contracts/DebitaLendOfferFactory.sol";
import {DLOImplementation} from "@contracts/DebitaLendOffer-Implementation.sol";
import {DebitaIncentives} from "@contracts/DebitaIncentives.sol";
import {Ownerships} from "@contracts/DebitaLoanOwnerShips.sol";
import {auctionFactoryDebita} from "@contracts/auctions/AuctionFactory.sol";
import {DebitaV3Loan} from "@contracts/DebitaV3Loan.sol";

//Oracle

import {DebitaChainlink} from "@contracts/oracles/DebitaChainlink.sol";

contract TestDebitaBorrower is Test {
    DBOImplementation dbImplem;
    DBOFactory dbFactory;
    DeployBorrowerScript deployer;
    veNFTEqualizer veNFTReceipt;
    MockveNFT mveNFT;
    MockERC20 merc20;
    DebitaV3Aggregator dAggregator;

    //oracle
    DebitaChainlink oracle;

    //for aggregator
    DLOFactory dlFactory;
    DLOImplementation dlImplem;
    DebitaIncentives dIncentivies;
    Ownerships dOwnership;
    auctionFactoryDebita dauctionFactory;
    DebitaV3Loan dLoan;

    address spider = makeAddr("spider");
    address void = makeAddr("void");

    address constant FOUNDRY_DEFAULT =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public {
        //Deployment for Debita Factory and Implementaation
        deployer = new DeployBorrowerScript();
        (dbFactory, dbImplem) = deployer.run();

        //deploy DLO factory and Implementation
        dlImplem = new DLOImplementation();
        dlFactory = new DLOFactory(address(dlImplem));

        //deploy Incentive
        dIncentivies = new DebitaIncentives();

        //deploy ownerShip
        dOwnership = new Ownerships();

        //deplpy AuctionFactory;
        dauctionFactory = new auctionFactoryDebita();

        //deploy Loan Implementation
        dLoan = new DebitaV3Loan();

        //deploy aggregator

        dAggregator = new DebitaV3Aggregator(
            address(dlFactory),
            address(dbFactory),
            address(dIncentivies),
            address(dOwnership),
            address(dauctionFactory),
            address(dLoan)
        );

        //deploy mock setUp

        mveNFT = new MockveNFT();
        merc20 = new MockERC20("WETH", "WETH");

        veNFTReceipt = new veNFTEqualizer(address(mveNFT), address(merc20));

        oracle = new DebitaChainlink(address(0), address(spider));

        vm.prank(FOUNDRY_DEFAULT);
        dbFactory.setAggregatorContract(address(dAggregator));
    }

    /*//////////////////////////////////////////////////////////////
                                FACTORY
    //////////////////////////////////////////////////////////////*/
    function test_ownerOfBorrowFactory() public {
        //Arrange
        //Act
        address own_er = dbFactory.owner();
        //Assert
        assertEq(
            own_er,
            FOUNDRY_DEFAULT,
            "As the it is deployed using vm.startBroadcast()"
        );
    }

    function test_createBorrowOffer() public {
        //Arrange
        //Act
        //Assert
    }
}
