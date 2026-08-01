// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockAggregator {
    // Allows you to change the behavior dynamically in your tests
    bool public mockIsLoan;

    // Call this from your setUp() or specific tests to change the outcome
    function setMockIsLoan(bool _isLoan) external {
        mockIsLoan = _isLoan;
    }

    // The exact function signature expected by the factory contract
    function isSenderALoan(address /* _sender */) external view returns (bool) {
        return mockIsLoan;
    }
}
