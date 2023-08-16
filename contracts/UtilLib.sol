// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./interfaces/IStaderConfig.sol";

library UtilLib {
    error ZeroAddress();

    /// @notice zero address check modifier
    function checkNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }
}
