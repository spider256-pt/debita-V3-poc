# Debita V3 - Auction Factory Security Review & PoC

## 📌 Overview
[cite_start]This repository contains an educational security review and a comprehensive Foundry testing suite for the `auctionFactoryDebita` smart contract[cite: 2]. [cite_start]Originally part of the Debita V3 protocol, this contract acts as a factory and registry for creating and managing Dutch auctions specifically for veNFTs[cite: 53]. 

[cite_start]*Note: The original Debita V3 repository was archived and made read-only on Jun 1, 2025[cite: 575]. [cite_start]This review is conducted purely for educational purposes and portfolio building[cite: 579].*

---

## 🛠️ Testing Methodology
The testing suite was built using **Foundry** to simulate a rigorous mainnet environment. Key methodologies include:
* [cite_start]**Mocking External Dependencies:** Developed standard Mock ERC721 and Mock ERC20 contracts to simulate veNFTs and liquidation tokens[cite: 120, 166]. [cite_start]Created a Mock Aggregator to accurately test the `isSenderALoan` liquidation logic[cite: 211].
* [cite_start]**State Manipulation & Pranking:** Utilized `vm.startPrank` and `vm.startBroadcast` to test complex access control modifiers (e.g., `onlyOwner` and `onlyAuctions`) and bypass Foundry's default EOA limitations[cite: 84, 480].
* [cite_start]**Integration Testing:** Verified pagination mechanics (`offset` and `limit`) across active and historical state ledgers[cite: 257, 494].


## 📜 License
This project respects the original `SPDX-License-Identifier: MIT` license of the Debita V3 protocol. The test files and mock contracts provided here are open-source and available for educational use.

---

# AuctionFactory




- ### Events:
    - `createdAuction()`: Emits when auction is created by the creater
    - `auctionEdited()`: Emits when auction is Edited by the creater
    - `auctionEnded()`: Emits when auction is canceled or finished.

- ### Mappings:
    - `isAuction`: Maps address of auction to a bool value(if true then auction do exist)

    - `AuctionOrderIndex`: Maps address of auction to active orders.

    - `allActiveAuctionOrders`: Maps active orders index to auction address.

- ### State VAriables:
    - uint FloorPricePercentage = 1500
    - uint auctionFeen = 200
    - uint publicAuctionFee = 50
    - uint deployedTime
    - address owner
    - address agregator
    - address feeAddress
    - address[] historicalAuctions

- ### Modifier
    - `onlOwner`
    - `onlyAuction`

- ### Functions
    - `createAuction()`
    - `getActiveAuctionOrders()`
    - `getLiquidationFloorPrice()`
    - `_deleteAuctionOrder()`
    - `getHistoricalAuctions()`
    - `getHistoricalAmount()`
    - `setFloorPriceForLiquidations()`
    - `changeAuctionFee()`
    - `changePublicAuctionsFee()`
    - `setAggregator()`
    - `setFeeAddress()`
    - `changeOwner()`
    - `emitAuctionDeleted()`
    - `emitAuctionEditied()`

- ## testCreateFunction 
    - ### Moks
        - `ERCveFT`: Address of the NFT for testing.

        - `ERC20`: Address of the token for testing.

    - ### function createAuction():
        - `parameters`:
            - _veNFTID 
            - _veNFTAddress
            - liquidationToken
            - _initAmount
            - _floorAmount
            - _duration

            - Need to deploy aggregator();

    - ### Logic Flow for getHistoricalAuctions(uint offset, uint limit)
        
        - uses address[] array historicalAuctions
        - if user created 6 auctions then it historicalAuction array will have 6 element.
        - if user call getHistoricalAuctions()
        ```logic FLow
        uint length = limit => 6
        if(6 > 6) => false skips the if block
        limit = 6
        result array DutchAuction_veNFT.dutchAuction_INFO[](
                length - offset
            ); => 6 - 0 as offset will use the default value which is 0.

        for loop iteration: 
        uint i = 0 
        i+offset < length  => 0+0 < 6 => true
        i++ => i = 1
         order address = allActiveAuctionOrders[0]
         i = 2
         order address = allActiveAuctionOrders[1]
         i = 3
         order address = allActiveAuctionOrders[2]
         i = 4
         order address = allActiveAuctionOrders[3]
         i = 5
         order address = allActiveAuctionOrders[4]
         i = 6
         i+offset < length  => 6+0 < 6 => false breaks the loop
         saves whole struct in AuctionInfo which stores 
         and push it to result array
        ```
        # Will continu.....
        

        

