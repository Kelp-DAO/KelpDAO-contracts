// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

/// @title UtilLib - Utility library
/// @notice Utility functions
library UtilLib {
    error ZeroAddressNotAllowed();

    /// @dev zero address check modifier
    /// @param _address address to check
    function checkNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddressNotAllowed();
    }
}
