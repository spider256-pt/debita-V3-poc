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

        //deploy this for the receipt
        veNFTReceipt = new veNFTEqualizer(address(mveNFT), address(merc20));

        oracle = new DebitaChainlink(address(0), address(void));

        vm.prank(FOUNDRY_DEFAULT);
        dbFactory.setAggregatorContract(address(dAggregator));

        uint256 tokenIdVOid = mveNFT.mint(void);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier createBorrow() {
        vm.startPrank(spider);

        uint256 collateralId = mveNFT.mint(spider);
        mveNFT.approve(address(veNFTReceipt), collateralId);

        uint[] memory deposit_nft = new uint[](1);
        deposit_nft[0] = collateralId;
        veNFTReceipt.deposit(deposit_nft);

        bool[] memory oracle = new bool[](1);
        oracle[0] = false;
        uint[] memory ltv = new uint[](1);
        ltv[0] = 5000;
        uint maxTinterest = 7000;
        uint duration = 86400;

        address[] memory acceptedPrinciple = new address[](1);
        acceptedPrinciple[0] = address(merc20);
        address _collateral = address(mveNFT);
        bool _isNFT = true;
        uint _receiptId = 1;
        address[] memory oracle_prin = new address[](1);
        oracle_prin[0] = address(0);
        uint[] memory ratio = new uint[](0);
        ratio[0] = 1e18;
        veNFTReceipt.approve(address(dbFactory), _receiptId);

        address _orcaleId_collateral = address(0);
        uint collateralAmount = 1;

        dbFactory.createBorrowOrder(
            oracle,
            ltv,
            maxTinterest,
            duration,
            acceptedPrinciple,
            _collateral,
            _isNFT,
            _receiptId,
            oracle_prin,
            ratio,
            _orcaleId_collateral,
            collateralAmount
        );
        _;
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                FACTORY
    //////////////////////////////////////////////////////////////*/

    function test_OwnerOfBorrowFactory() public {
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

    function test_TokenId() public {
        vm.startPrank(spider);
        uint256 tokenId = mveNFT.mint(spider);
        console.log(tokenId);
    }

    //active borrow offer function testing
    function test_createBorrowOffer() public {
        //Arrange

        vm.startPrank(spider);

        uint256 collateralId = mveNFT.mint(spider);
        mveNFT.approve(address(veNFTReceipt), collateralId);

        uint[] memory depositArray = new uint[](1);
        depositArray[0] = collateralId;

        veNFTReceipt.deposit(depositArray);

        bool[] memory oracle = new bool[](1);
        oracle[0] = false;

        uint[] memory ltv = new uint[](1);
        ltv[0] = 5000;

        uint maxInterest = 7000;
        uint duration = 86400; //1 day o 24 hrs

        address[] memory principle = new address[](1);
        principle[0] = address(merc20);

        address collateral = address(veNFTReceipt);

        bool _isNFT = true;

        uint _receiptId = 1;
        veNFTReceipt.approve(address(dbFactory), _receiptId);

        address[] memory oracleAddresses = new address[](1);
        oracleAddresses[0] = address(0);

        uint[] memory ratio = new uint[](1);
        ratio[0] = 1e18;

        uint collateralAmount = 1;

        console.log("collateral Amount", collateralAmount);

        //Act

        address created_borrowAddress = dbFactory.createBorrowOrder(
            oracle,
            ltv,
            maxInterest,
            duration,
            principle,
            collateral,
            _isNFT,
            _receiptId,
            oracleAddresses,
            ratio,
            address(0),
            collateralAmount
        );

        // uint256 balanceOfUserErc20 = merc20.balanceOf(spider);
        // uint256 balancofUserNFT = mveNFT.balanceOf(spider);
        // uint256 balacneOfContract = mveNFT.balanceOf(address(dbFactory));

        // console.log(balanceOfUserErc20);
        // console.log(balancofUserNFT);
        // console.log(balacneOfContract);

        //Assert
        assertEq(dbFactory.activeOrdersCount(), 1, "active Borrow not created");
        assertEq(
            dbFactory.isBorrowOrderLegit(address(created_borrowAddress)),
            true,
            "Borrow order if created then should be true"
        );
        assertEq(
            dbFactory.borrowOrderIndex(address(created_borrowAddress)),
            0,
            "Created Borrow order index should be 1"
        );
        assertEq(
            veNFTReceipt.balanceOf(created_borrowAddress),
            1,
            "Balance of created Address should be 1"
        );
    }

    function test_RevertIfTheCollateralIsNotAnNFT() public {
        //Arrange
        vm.startPrank(spider);

        uint256 collateralId = mveNFT.mint(spider);
        mveNFT.approve(address(veNFTReceipt), collateralId);

        uint[] memory depositArray = new uint[](1);
        depositArray[0] = collateralId;

        veNFTReceipt.deposit(depositArray);

        bool[] memory oracle = new bool[](1);
        oracle[0] = false;

        uint[] memory ltv = new uint[](1);
        ltv[0] = 5000;

        uint maxInterest = 7000;
        uint duration = 86400; //1 day o 24 hrs

        address[] memory principle = new address[](1);
        principle[0] = address(merc20);

        address collateral = address(merc20);

        bool _isNFT = true;

        uint _receiptId = 1;
        veNFTReceipt.approve(address(dbFactory), _receiptId);

        address[] memory oracleAddresses = new address[](1);
        oracleAddresses[0] = address(0);

        uint[] memory ratio = new uint[](1);
        ratio[0] = 1e18;

        uint collateralAmount = 1;

        console.log("collateral Amount", collateralAmount);

        //Act

        vm.expectRevert();
        address created_borrowAddress = dbFactory.createBorrowOrder(
            oracle,
            ltv,
            maxInterest,
            duration,
            principle,
            collateral,
            _isNFT,
            _receiptId,
            oracleAddresses,
            ratio,
            address(0),
            collateralAmount
        );
        //Assert
        assertEq(
            dbFactory.activeOrdersCount(),
            0,
            "The order should not exist"
        );
        vm.stopPrank();
    }

    function test_RevertIfCollateralisZeroAddress() public {
        vm.startPrank(spider);

        uint256 collateralId = mveNFT.mint(spider);
        mveNFT.approve(address(veNFTReceipt), collateralId);

        uint[] memory depositArray = new uint[](1);
        depositArray[0] = collateralId;

        veNFTReceipt.deposit(depositArray);

        bool[] memory oracle = new bool[](1);
        oracle[0] = false;

        uint[] memory ltv = new uint[](1);
        ltv[0] = 5000;

        uint maxInterest = 7000;
        uint duration = 86400; //1 day o 24 hrs

        address[] memory principle = new address[](1);
        principle[0] = address(merc20);

        address collateral = address(0);

        bool _isNFT = true;

        uint _receiptId = 1;
        veNFTReceipt.approve(address(dbFactory), _receiptId);

        address[] memory oracleAddresses = new address[](1);
        oracleAddresses[0] = address(0);

        uint[] memory ratio = new uint[](1);
        ratio[0] = 1e18;

        uint collateralAmount = 1;

        console.log("collateral Amount", collateralAmount);

        //Act
        vm.expectRevert();
        address created_borrowAddress = dbFactory.createBorrowOrder(
            oracle,
            ltv,
            maxInterest,
            duration,
            principle,
            collateral,
            _isNFT,
            _receiptId,
            oracleAddresses,
            ratio,
            address(0),
            collateralAmount
        );

        //Assert
        assertEq(
            dbFactory.activeOrdersCount(),
            0,
            "The order should not exist"
        );
        vm.stopPrank();
    }

    function test_RevertIfCollateralAmountisSomeRandomAddress() public {
        vm.startPrank(spider);

        uint256 collateralId = mveNFT.mint(spider);
        mveNFT.approve(address(veNFTReceipt), collateralId);

        uint[] memory depositArray = new uint[](1);
        depositArray[0] = collateralId;

        veNFTReceipt.deposit(depositArray);

        bool[] memory oracle = new bool[](1);
        oracle[0] = false;

        uint[] memory ltv = new uint[](1);
        ltv[0] = 5000;

        uint maxInterest = 7000;
        uint duration = 86400; //1 day o 24 hrs

        address[] memory principle = new address[](1);
        principle[0] = address(merc20);

        address collateral = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        bool _isNFT = true;

        uint _receiptId = 1;
        veNFTReceipt.approve(address(dbFactory), _receiptId);

        address[] memory oracleAddresses = new address[](1);
        oracleAddresses[0] = address(0);

        uint[] memory ratio = new uint[](1);
        ratio[0] = 1e18;

        uint collateralAmount = 1;

        console.log("collateral Amount", collateralAmount);

        //Act
        vm.expectRevert();
        address created_borrowAddress = dbFactory.createBorrowOrder(
            oracle,
            ltv,
            maxInterest,
            duration,
            principle,
            collateral,
            _isNFT,
            _receiptId,
            oracleAddresses,
            ratio,
            address(0),
            collateralAmount
        );

        //Assert
        assertEq(
            dbFactory.activeOrdersCount(),
            0,
            "The order should not exist"
        );
        vm.stopPrank();
    }

    function test_deleteBorrowOrder() public createBorrow {
        //Arrange
        //Act
        //Assert
    }
}
