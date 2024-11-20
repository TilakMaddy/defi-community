// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library Errors {
    // Faucet errors
    error IltmuelcMintIntervalNotMet();

    // Wen Game errors
    error IltmuelcInsufficientFunds();
    error IltmuelcAlreadyParticipated();
    error IltmuelcNotParticipated();
    error IltmuelcGameEnded();
    error IltmuelcGameHasNotEnded();
    error IltmuelcAlreadyPaid();
    error IltmuelcNonWinnerClaim();
}
