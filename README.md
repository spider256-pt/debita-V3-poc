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

---

## 🚨 Vulnerabilities & Findings

During the development of the Proof of Concept (PoC) tests, several vulnerabilities and architectural quirks were identified:

### 1. [Critical] State Variable Shadowing in `changeOwner`
[cite_start]The `changeOwner` function contains a severe shadowing bug that renders it completely non-functional[cite: 55]. 
* [cite_start]**Details:** The parameter `address owner` shadows the state variable `owner`[cite: 56]. [cite_start]Because of this, the `require(msg.sender == owner)` statement checks if the caller is the address passed in the argument, not the actual contract owner[cite: 57]. [cite_start]The assignment `owner = owner;` simply assigns the parameter to itself, leaving the contract state permanently unchanged[cite: 58].

### 2. [High] Arithmetic Underflow in Pagination Logic
[cite_start]Both the `getActiveAuctionOrders` and `getHistoricalAuctions` functions are susceptible to arithmetic underflows[cite: 60].
* [cite_start]**Details:** When the contract initializes the memory array to return the data, it uses the logic `new DutchAuction_veNFT.dutchAuction_INFO[](length - offset)`[cite: 25, 280]. [cite_start]If a user queries an offset that is larger than the limit or the total array length, this subtraction causes an underflow panic in Solidity ^0.8.0, breaking front-end integrations[cite: 61, 280].

### 3. [Medium] Access Control Flaw in `_deleteAuctionOrder`
A subtle logic flaw allows any registered auction to delete competitor auctions from the active registry.
* [cite_start]**Details:** The function signature is `_deleteAuctionOrder(address _AuctionOrder) external onlyAuctions`[cite: 30]. [cite_start]The `onlyAuctions` modifier only verifies that the `msg.sender` is *a* registered auction[cite: 429]. [cite_start]It never verifies that `msg.sender == _AuctionOrder`[cite: 429]. [cite_start]Consequently, any active auction technically possesses the permission to delete any other active auction from the tracking array[cite: 430].

### 4. [Info] State Mismatch on Auction Deletion
[cite_start]When an auction is deleted via `_deleteAuctionOrder`, it is successfully removed from the `allActiveAuctionOrders` array[cite: 32]. However, the contract never sets `isAuction[_AuctionOrder] = false;`[cite: 419]. [cite_start]The deleted auction remains permanently marked as a valid auction in the boolean mapping[cite: 420].

---

## 💻 How to Run the Tests

To run this testing suite locally, ensure you have [Foundry](https://book.getfoundry.sh/) installed.

1. **Clone the repository:**
   `git clone <YOUR_REPO_URL>`
2. **Install dependencies:**
   `forge install`
3. **Run the test suite:**
   `forge test -vvv`

---

## 📜 License
This project respects the original `SPDX-License-Identifier: MIT` license of the Debita V3 protocol. The test files and mock contracts provided here are open-source and available for educational use.



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
        

        

