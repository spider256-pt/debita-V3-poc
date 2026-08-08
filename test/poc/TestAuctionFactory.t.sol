//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {auctionFactoryDebita} from "@contracts/auctions/AuctionFactory.sol";
import {Test, console} from "forge-std/Test.sol";
import {
    DeployAuctionFactory
} from "../../script/poc/DeployAuctionFactory.s.sol";
import {DutchAuction_veNFT} from "@contracts/auctions/Auction.sol";
import {MockveNFT} from "../../mockTokens/mockveNFT.sol";
import {MockERC20} from "../../mockTokens/mockERC20.sol";

//Requirements for DebitaV3Aggregator.
import {DebitaV3Aggregator} from "@contracts/DebitaV3Aggregator.sol";
import {DBOFactory} from "@contracts/DebitaBorrowOffer-Factory.sol";
import {
    DBOImplementation
} from "@contracts/DebitaBorrowOffer-Implementation.sol";
import {DLOFactory} from "@contracts/DebitaLendOfferFactory.sol";
import {DLOImplementation} from "@contracts/DebitaLendOffer-Implementation.sol";
import {DebitaIncentives} from "@contracts/DebitaIncentives.sol";
import {Ownerships} from "@contracts/DebitaLoanOwnerships.sol";
import {DebitaV3Loan} from "@contracts/DebitaV3Loan.sol";

contract TestAuctionFactory is Test {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    auctionFactoryDebita public aDebita;
    DeployAuctionFactory public deployer;

    //Aggregator
    DebitaV3Aggregator public aggregator;
    DBOFactory public dboFactory;
    DBOImplementation public DBOImplmen;
    DLOFactory public dloFactory;
    DLOImplementation public DLOImplmen;
    DebitaIncentives public debitaIncentives;
    Ownerships public ownerships;
    DebitaV3Loan public debitaV3Loan;

    MockERC20 mERC20;
    MockveNFT mveNFT;

    address owner = makeAddr("owner");
    address spider = makeAddr("spider");

    address constant FOUNDRY_DEFAULT =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        deployer = new DeployAuctionFactory();
        aDebita = deployer.run();

        mERC20 = new MockERC20("WETH", "WETH");
        mveNFT = new MockveNFT();

        DBOImplmen = new DBOImplementation();
        DLOImplmen = new DLOImplementation();
        debitaIncentives = new DebitaIncentives();
        ownerships = new Ownerships();
        debitaV3Loan = new DebitaV3Loan();

        //Deploy
        dboFactory = new DBOFactory(address(DBOImplmen));
        dloFactory = new DLOFactory(address(DLOImplmen));

        aggregator = new DebitaV3Aggregator(
            address(dboFactory),
            address(dloFactory),
            address(debitaIncentives),
            address(ownerships),
            address(aDebita),
            address(debitaV3Loan)
        );

        vm.prank(FOUNDRY_DEFAULT);
        aDebita.setAggregator(address(aggregator));
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier createAuction() {
        vm.startPrank(spider);

        //Act
        for (uint256 i = 0; i < 6; i++) {
            uint256 testId = mveNFT.mint(spider);
            mveNFT.approve(address(aDebita), testId);

            address auctionAddress = aDebita.createAuction(
                testId,
                address(mveNFT),
                address(mERC20),
                200,
                100,
                86400
            );
        }
        _;
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Test owner is set or not.
     */
    function testOwnerSet() public {
        address feeAddress = aDebita.feeAddress();
        console.log("feeAddress = owner Address", feeAddress);
        assertEq(feeAddress, FOUNDRY_DEFAULT);
    }

    /**
     * @dev Test createAuction() function.
     */
    function testcreateAuction() public {
        //Arrange
        vm.startPrank(spider);
        uint256 testId = mveNFT.mint(spider);
        mveNFT.approve(address(aDebita), testId);

        //Act
        address auctionAddress = aDebita.createAuction(
            testId,
            address(mveNFT),
            address(mERC20),
            200,
            100,
            86400
        );
        vm.stopPrank();
        //Assert
        assertTrue(auctionAddress != address(0), "Auction Not created");
        bool isRegistered = aDebita.isAuction(auctionAddress);
        assertTrue(isRegistered, "Auciton is not Registered");
        assertEq(
            aDebita.activeOrdersCount(),
            1,
            "Active orders count should be 1"
        );
    }

    /**
     * @dev Test to get Active Auction
     */
    function testgetActiveAuctionOrders() public createAuction {
        //Arrange
        //Act
        DutchAuction_veNFT.dutchAuction_INFO[] memory results = aDebita
            .getActiveAuctionOrders(0, 6);
        //Assert
        assertEq(aDebita.activeOrdersCount(), 6, "There should be 6 auction");
        assertEq(results.length, 6);
    }

    /**
     * @dev Test To get the Liquidation Floor price.
     */

    function testgetLiquidationFloorPrice(uint256 initAmount) public {
        //Arrange
        initAmount = bound(initAmount, 0, 1e9);

        //Act
        uint256 floorPrice = aDebita.getLiquidationFloorPrice(initAmount);

        //Assert
        assertEq(
            floorPrice,
            (initAmount * 1500) / 10000,
            "floorPrice crashed for some values"
        );
    }

    function testdeleteAuctionOrder() public createAuction {
        //Arrange
        uint256 InitialauctionCount = aDebita.activeOrdersCount();
        address auctionAddress = aDebita.allActiveAuctionOrders(0);
        //Act
        vm.startPrank(auctionAddress);
        aDebita._deleteAuctionOrder(auctionAddress);
        uint256 FinalAuctionCount = aDebita.activeOrdersCount();
        //Assert
        assertEq(InitialauctionCount, 6, "Modifier did not work");
        assertEq(FinalAuctionCount, 5, "Final auction count should be 5");
        bool isRegistered = aDebita.isAuction(auctionAddress);
        assertEq(isRegistered, true, "is Auction should be false");
    }

    function testgetHistoricalAuctions() public createAuction {
        //Arrange
        uint256 auctionCount = aDebita.activeOrdersCount();
        address auctionAddress = aDebita.allActiveAuctionOrders(0);

        vm.startPrank(auctionAddress);
        aDebita._deleteAuctionOrder(auctionAddress);
        vm.stopPrank();

        uint256 countActiveAuctionAfterDelete = aDebita.activeOrdersCount();

        uint256 auctionCountAfterDelete = aDebita.getHistoricalAmount();
        //Act
        DutchAuction_veNFT.dutchAuction_INFO[] memory results = aDebita
            .getHistoricalAuctions(0, 6);
        //Assert

        assertEq(results.length, 6, "There should be 6 auction");
        assertEq(countActiveAuctionAfterDelete, 5, "This should be 5");
        assertEq(auctionCount, 6, "6 auction were created");
        assertEq(auctionCountAfterDelete, 6, "There should be 6 auction");
    }

    /**
     * @dev test changeOwner byt changing the visibility of owner state or vm.load can also be used
     */
    // function testChangeOwner() public {
    //     vm.startPrank(spider);
    //     address initialOnwer = aDebita.owner();
    //     console.log("initialOnwer", initialOnwer);
    //     aDebita.changeOwner(spider);
    //     vm.warp(1 days);
    //     address newOwner = aDebita.owner();
    //     assertEq(initialOnwer, FOUNDRY_DEFAULT);
    //     assertNotEq(newOwner, spider);
    //     assertEq(newOwner, initialOnwer);
    // }

    function testRevertIfFsetFloorPriceForLiquidationsExceedsRanges(
        uint256 ratio
    ) public {
        //Arrange
        vm.startPrank(FOUNDRY_DEFAULT);
        ratio = bound(ratio, 3001, type(uint256).max);
        //Act
        vm.expectRevert();
        aDebita.setFloorPriceForLiquidations(ratio);
        uint256 floorPriceChanged = aDebita.FloorPricePercentage();
        vm.stopPrank();
        //Assert
        // assertEq(
        //     floorPriceChanged,
        //     ratio,
        //     "The ratio and FloorPrice should be same"
        // );
    }

    function testRevertIfFsetFloorPriceForLiquidationsIsUnderRange(
        uint256 ratio
    ) public {
        //Arrange
        vm.startPrank(FOUNDRY_DEFAULT);
        ratio = bound(ratio, 0, 499);
        //Act
        vm.expectRevert();
        aDebita.setFloorPriceForLiquidations(ratio);
        uint256 floorPriceChanged = aDebita.FloorPricePercentage();
        vm.stopPrank();
        //Assert
        // assertEq(
        //     floorPriceChanged,
        //     ratio,
        //     "The ratio and FloorPrice should be same"
        // );
    }

    function testRevertifchangeAuctionFeeExceedsRange(uint256 fee) public {
        //Arrange
        vm.startPrank(FOUNDRY_DEFAULT);
        fee = bound(fee, 401, type(uint256).max);
        //Act
        vm.expectRevert();
        aDebita.changeAuctionFee(fee);
        vm.stopPrank();
        //Assert
    }

    function testRevertifchangeAuctionFeeIsUnderRange(uint256 fee) public {
        //Arrange
        vm.startPrank(FOUNDRY_DEFAULT);
        fee = bound(fee, 0, 49);
        //Act//Assert
        vm.expectRevert();
        aDebita.changeAuctionFee(fee);
        vm.stopPrank();
    }

    function testRevertIfchangePublicAuctionFeeExceedsRange(
        uint256 fee
    ) public {
        //Arrange
        vm.startPrank(FOUNDRY_DEFAULT);
        fee = bound(fee, 101, type(uint256).max);
        vm.expectRevert();
        aDebita.changePublicAuctionFee(fee);
        //Act //Assert
        vm.stopPrank();
    }
}
