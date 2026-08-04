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

        uint256 tokenId = mveNFT.mint(FOUNDRY_DEFAULT);

        vm.startPrank(FOUNDRY_DEFAULT);
        mveNFT.approve(address(aDebita), tokenId);
        address aDebitaAuction = aDebita.createAuction(
            tokenId,
            address(mveNFT),
            address(mERC20),
            200,
            100,
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
        assertEq(FOUNDRY_DEFAULT, owner, "The default should be the owner");
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
}
