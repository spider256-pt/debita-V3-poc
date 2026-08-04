//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DutchAuction_veNFT} from "@contracts/auctions/Auction.sol";
import {MockveNFT} from "../../mockTokens/mockveNFT.sol";
import {MockERC20} from "../../mockTokens/mockERC20.sol";
import {auctionFactoryDebita} from "@contracts/auctions/AuctionFactory.sol";

//Requirements for DebitaV3Aggregator.
import {
    DeployAuctionFactory
} from "../../script/poc/DeployAuctionFactory.s.sol";
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

contract TestAuction is Test {
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/

    auctionFactoryDebita public aDebita;
    DutchAuction_veNFT public auction;
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

    address constant FOUNDRY_DEFAULT =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    address spider = makeAddr("spider");
    address void = makeAddr("void");

    /*//////////////////////////////////////////////////////////////
                                  TEST
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

        //
        vm.prank(FOUNDRY_DEFAULT);
        aDebita.setAggregator(address(aggregator));

        vm.startPrank(void);
        uint256 tokenId = mveNFT.mint(void);
        mveNFT.approve(address(aDebita), tokenId);
        address aDebitaAuction = aDebita.createAuction(
            tokenId,
            address(mveNFT),
            address(mERC20),
            1e18,
            1e10,
            86400
        );
        vm.stopPrank();

        auction = DutchAuction_veNFT(aDebitaAuction);
    }

    function testOwnerOftheAuction() public {
        //Arrange

        //Act
        address owner = auction.s_ownerOfAuction();
        console.log(owner);
        //Assert
        assertEq(void, owner, "The default should be the owner");
    }

    function test_Factory() public {
        //Arrange
        //Act
        address s_factory = auction.factory();
        console.log(s_factory);
        //Assert
    }

    function testbuy_NFT() public {
        //Arrange

        vm.startPrank(spider);
        mERC20.mint(spider, 1e18);
        mERC20.approve(address(auction), 1e18);

        uint256 initial_balanceofERCUser = mERC20.balanceOf(spider);
        uint256 initial_balanceOfNFT = mveNFT.balanceOf(spider);
        console.log(initial_balanceofERCUser);
        console.log(initial_balanceOfNFT);
        //Act
        auction.buyNFT();
        uint256 Final_balanceofERCUser = mERC20.balanceOf(spider);
        uint256 Final_balanceOfNFT = mveNFT.balanceOf(spider);
        console.log(Final_balanceofERCUser);
        console.log(Final_balanceOfNFT);

        //Assert
        assertEq(initial_balanceofERCUser, 1e18);
        assertEq(initial_balanceOfNFT, 0);
        assertLt(
            Final_balanceofERCUser,
            initial_balanceofERCUser,
            "The user should have received the NFT"
        );
        assertEq(Final_balanceOfNFT, 1);
    }

    function testbuy_NFT3times() public {
        //Arrange

        vm.startPrank(spider);
        mERC20.mint(spider, 1e18);
        mERC20.approve(address(auction), 1e18);

        uint256 initial_balanceofERCUser = mERC20.balanceOf(spider);
        uint256 initial_balanceOfNFT = mveNFT.balanceOf(spider);
        console.log(initial_balanceofERCUser);
        console.log(initial_balanceOfNFT);
        //Act
        auction.buyNFT();
        uint256 fianl_NFTBalance = mveNFT.balanceOf(spider);
        console.log("the protocol is for 1 to one");
        vm.expectRevert();
        auction.buyNFT();

        //Assert
        assertEq(fianl_NFTBalance, 1);
    }

    function test_cancelAuction() public {
        //Arrange

        vm.startPrank(void);
        uint256 x = aDebita.activeOrdersCount();
        console.log(x);
        auction.cancelAuction();
        uint256 y = aDebita.activeOrdersCount();
        vm.stopPrank();
        //Assert
        assertEq(y, 0, "The active auctions shoudl be 0");
    }

    function test_RevertIfcancelAuctionCalledbyNoneOwner() public {
        //Arrange
        vm.startPrank(spider);
        //Act
        uint256 x = aDebita.activeOrdersCount();
        console.log(x);
        vm.expectRevert();
        auction.cancelAuction();
        //Assert
        assertEq(
            aDebita.activeOrdersCount(),
            x,
            "The non-owner can cancel a auction"
        );
    }

    function test_RevertIfcancelAuctionisCalledAfterbuy_NFT() public {
        //Arrange
        vm.startPrank(void);
        mERC20.mint(void, 1e18);
        mERC20.approve(address(auction), 1e18);
        uint256 activAuctionCount = aDebita.activeOrdersCount();

        //Act
        auction.buyNFT();

        uint256 activeAuctionAfterBuy = aDebita.activeOrdersCount();

        vm.expectRevert();
        auction.cancelAuction();
        //Assert
        assertEq(activAuctionCount, 1);
        assertEq(activeAuctionAfterBuy, 0);
        vm.stopPrank();
    }

    function test_editFloorPrice(uint256 newValue) public {
        //Arrange
        newValue = bound(newValue, 0, 1e9);
        vm.startPrank(void);
        //Act
        auction.editFloorPrice(newValue);
        vm.stopPrank();
        //Assert
        assertEq(newValue, auction.getAuctionData().floorAmount);
    }

    function test_RevertIfNonOwnerTriesToSetNewFloor(uint256 newValue) public {
        //Arrange
        newValue = bound(newValue, 0, 1e9);
        vm.startPrank(spider);
        //Act
        vm.expectRevert();
        auction.editFloorPrice(newValue);
        vm.stopPrank();
        //Assert
        assertEq(
            auction.getAuctionData().floorAmount,
            1e10,
            "shoudl not be changed"
        );
    }

    function test_RevertIfOwnerTriesTOSetNewFloorValueAfterAuctionDeleted()
        public
    {
        //Arrange
        vm.startPrank(void);
        auction.cancelAuction();
        uint256 afterCancelingTheAuction = aDebita.activeOrdersCount();

        //Act
        vm.expectRevert();
        auction.editFloorPrice(1e9);
        //Assert
        assertEq(
            afterCancelingTheAuction,
            0,
            "The auction should be deleted and the active auction count should be 0"
        );
    }

    function test_RevertIFOwnerSetNewFloorvValueGretterOrEqualstoCurrentFloorValue(
        uint256 newValue
    ) public {
        //Arrange
        vm.startPrank(void);
        uint256 currentfloorValue = auction.getAuctionData().floorAmount;
        newValue = bound(newValue, currentfloorValue, type(uint256).max);
        //Act
        vm.expectRevert();
        auction.editFloorPrice(newValue);
        vm.stopPrank();
        //Assert
        assertEq(auction.getAuctionData().floorAmount, currentfloorValue);
    }

    function test_getCurrentPrice() public {
        //Arrange
        vm.startPrank(spider);

        //Act
        uint256 initial_price = auction.getCurrentPrice();
        uint256 no_dayPAss = auction.getCurrentPrice();
        vm.warp(1 days);
        uint256 aDay_passed_Price = auction.getCurrentPrice();
        vm.warp(7 days);
        uint256 twoDays_passed_price = auction.getCurrentPrice();
        //Assert
        assertEq(initial_price, no_dayPAss, "It should be Equal");
        assertGt(no_dayPAss, aDay_passed_Price, "Price should drop");
        assertLt(twoDays_passed_price, aDay_passed_Price, "Price should drop");
    }

    function test_RevertIfTheReturnValueIncreasedAfterTimePasses(
        uint256 time
    ) public {
        //Arrange
        time = bound(time, 1 days, 19 days);
        vm.startPrank(spider);
        //Act
        uint256 init_price = auction.getCurrentPrice();
        vm.warp(block.timestamp + time);
        uint256 final_price = auction.getCurrentPrice();

        //Assert
        assertLe(
            final_price,
            init_price,
            "The price should have dropped or equal"
        );
    }
}
