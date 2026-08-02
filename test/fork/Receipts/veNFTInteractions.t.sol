pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {veNFTAerodrome} from "@contracts/Non-Fungible-Receipts/veNFTS/Aerodrome/Receipt-veNFT.sol";

import {veNFTVault} from "@contracts/Non-Fungible-Receipts/veNFTS/Equalizer/veNFTEqualizer.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {veNFTVault} from "@contracts/Non-Fungible-Receipts/veNFTS/Equalizer/veNFTEqualizer.sol";
import {VotingEscrow} from "@aerodrome/VotingEscrow.sol";
import {Gauge} from "@aerodrome/gauges/Gauge.sol";
import {Voter} from "@aerodrome/Voter.sol";
import {BribeVotingReward} from "@aerodrome/rewards/BribeVotingReward.sol";

contract CounterTest is Test {
    VotingEscrow public ABIERC721Contract;
    veNFTAerodrome public receiptContract;
    veNFTVault[] public veNFTVaultContract = new veNFTVault[](3);
    ERC20Mock public TOKEN;
    address[] vaultAddress = new address[](3);
    uint256[] nftID = new uint256[](3);
    uint256[] receiptID = new uint256[](3);
    address[] poolAddresses = [
        0x6cDcb1C4A4D1C3C6d054b27AC5B77e89eAFb971d,
        0xb2cc224c1c9feE385f8ad6a55b4d94E92359DC59,
        0xBd1F3d188de7eE07B1b323C0D26D6720CAfB8780
    ];
    address[] gaugesAddresses = [0xF33a96b5932D9E9B9A0eDA447AbD8C9d48d2e0c8];
    address veAERO = 0xeBf418Fe2512e7E6bd9b87a8F0f294aCDC67e6B4;
    address AERO = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;

    function setUp() public {
        ABIERC721Contract = VotingEscrow(veAERO);
        TOKEN = ERC20Mock(AERO);
        receiptContract = new veNFTAerodrome(address(ABIERC721Contract), AERO);

        deal(AERO, address(this), 1000e18, true);
        TOKEN.approve(address(ABIERC721Contract), 1000e18);

        for (uint256 i = 0; i < 3; i++) {
            uint256 id = ABIERC721Contract.createLock(100e18, 365 * 4 * 86400);
            ABIERC721Contract.approve(address(receiptContract), id);
            nftID[i] = id;
        }

        receiptContract.deposit(nftID);

        for (uint256 i = 0; i < 3; i++) {
            receiptID[i] = receiptContract.lastReceiptID() - 2 + i;
            address vault = receiptContract.s_ReceiptID_to_Vault(receiptID[i]);
            vaultAddress[i] = vault;
            veNFTVaultContract[i] = (veNFTVault(vault));
        }
    }

    /*
    TEST VOTING & ALL THE INTERACTIONS
    */
    function testVote() public {
        uint256[] memory weights = getDynamicUintArray(3);
        address[] memory voters = getDynamicAddressArray(3);
        vm.roll(block.number + 1);
        for (uint256 i; i < 3; i++) {
            voters[i] = poolAddresses[i];
            weights[i] = i == 0 ? 20000000000000000000 : 40000000000000000000;
        }
        receiptContract.voteMultiple(vaultAddress, voters, weights);
    }

    function testVoteBribeAndClaim() public {
        testVote();
        address[] memory arrayOfTokens = getDynamicAddressArray(1);
        address[] memory arrayOfBribes = getDynamicAddressArray(1);

        address bribeContract = Voter(0x16613524e02ad97eDfeF371bC883F2F5d6C480A5).gaugeToBribe(gaugesAddresses[0]);
        TOKEN.approve(bribeContract, 100e18);
        BribeVotingReward(bribeContract).notifyRewardAmount(AERO, 100e18);
        address[][] memory tokensAddresses = getDynamicAddressArrayArray(1);
        arrayOfTokens[0] = AERO;
        arrayOfBribes[0] = bribeContract;
        tokensAddresses[0] = arrayOfTokens;
        vm.roll(block.number + 10);
        vm.warp(block.timestamp + (86400 * 30));
        uint256 balanceBefore = TOKEN.balanceOf(address(this));
        receiptContract.claimBribesMultiple(vaultAddress, arrayOfBribes, tokensAddresses);
        uint256 balanceAfter = TOKEN.balanceOf(address(this));
        assertEq(true, balanceAfter > balanceBefore);
    }

    function testExpectErrorVoteBribeAndClaim() public {
        testVote();
        address[] memory arrayOfTokens = getDynamicAddressArray(1);
        address[] memory arrayOfBribes = getDynamicAddressArray(1);

        address bribeContract = Voter(0x16613524e02ad97eDfeF371bC883F2F5d6C480A5).gaugeToBribe(gaugesAddresses[0]);
        TOKEN.approve(bribeContract, 100e18);
        BribeVotingReward(bribeContract).notifyRewardAmount(AERO, 100e18);
        address[][] memory tokensAddresses = getDynamicAddressArrayArray(1);
        arrayOfTokens[0] = AERO;
        arrayOfBribes[0] = bribeContract;
        tokensAddresses[0] = arrayOfTokens;
        vm.roll(block.number + 10);
        vm.warp(block.timestamp + (86400 * 30));
        uint256 balanceBefore = TOKEN.balanceOf(address(this));
        vm.startPrank(0x548D484F5d768a497A1919a57f643AEF403FE3BE);
        vm.expectRevert(bytes("not manager"));
        receiptContract.claimBribesMultiple(vaultAddress, arrayOfBribes, tokensAddresses);
        vm.stopPrank();
    }

    function getDynamicAddressArrayArray(uint256 x) public pure returns (address[][] memory) {
        // declare new array of array of addresses length of x
        address[][] memory nftsID = new address[][](x);
        // return the array of array of addresses
        return nftsID;
    }

    function getDynamicUintArray(uint256 x) public pure returns (uint256[] memory) {
        uint256[] memory nftsID = new uint256[](x);
        return nftsID;
    }

    function getDynamicAddressArray(uint256 x) public pure returns (address[] memory) {
        address[] memory nftsID = new address[](x);
        return nftsID;
    }
}
