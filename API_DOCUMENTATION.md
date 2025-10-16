# Boring Vault Architecture - API Documentation

## Table of Contents
1. [BoringVault](#boringvault)
2. [ManagerWithMerkleVerification](#managerwithmerkleverification)
3. [TellerWithMultiAssetSupport](#tellerwithmultiassetsupport)
4. [AccountantWithRateProviders](#accountantwithrateproviders)
5. [AtomicQueue](#atomicqueue)
6. [Cross-Chain Components](#cross-chain-components)

## BoringVault

### Overview
Core vault contract that manages assets and shares.

### Functions

#### `constructor(address _owner, string memory _name, string memory _symbol, uint8 _decimals)`
Initializes the vault with basic ERC20 parameters.

**Parameters:**
- `_owner`: Address that will own the vault
- `_name`: Name of the vault token
- `_symbol`: Symbol of the vault token
- `_decimals`: Number of decimals for the token

#### `manage(address target, bytes calldata data, uint256 value) external returns (bytes memory result)`
Executes a function call on behalf of the vault.

**Parameters:**
- `target`: Address to call
- `data`: Calldata for the function call
- `value`: ETH value to send with the call

**Returns:**
- `result`: Return data from the function call

**Access Control:** MANAGER_ROLE

#### `manage(address[] calldata targets, bytes[] calldata data, uint256[] calldata values) external returns (bytes[] memory results)`
Executes multiple function calls atomically.

**Parameters:**
- `targets`: Array of addresses to call
- `data`: Array of calldata for each call
- `values`: Array of ETH values for each call

**Returns:**
- `results`: Array of return data from each call

**Access Control:** MANAGER_ROLE

#### `enter(address from, ERC20 asset, uint256 assetAmount, address to, uint256 shareAmount) external`
Mints shares in exchange for assets.

**Parameters:**
- `from`: Address to transfer assets from
- `asset`: ERC20 token to deposit
- `assetAmount`: Amount of assets to deposit
- `to`: Address to mint shares to
- `shareAmount`: Amount of shares to mint

**Access Control:** MINTER_ROLE

#### `exit(address to, ERC20 asset, uint256 assetAmount, address from, uint256 shareAmount) external`
Burns shares in exchange for assets.

**Parameters:**
- `to`: Address to send assets to
- `asset`: ERC20 token to withdraw
- `assetAmount`: Amount of assets to withdraw
- `from`: Address to burn shares from
- `shareAmount`: Amount of shares to burn

**Access Control:** BURNER_ROLE

#### `setBeforeTransferHook(address _hook) external`
Sets the before transfer hook contract.

**Parameters:**
- `_hook`: Address of the hook contract (0 to disable)

**Access Control:** OWNER_ROLE

### Events

#### `Enter(address indexed from, address indexed asset, uint256 amount, address indexed to, uint256 shares)`
Emitted when shares are minted.

#### `Exit(address indexed to, address indexed asset, uint256 amount, address indexed from, uint256 shares)`
Emitted when shares are burned.

## ManagerWithMerkleVerification

### Overview
Manages strategy execution with merkle tree verification.

### Functions

#### `constructor(address _owner, address _vault, address _balancerVault)`
Initializes the manager.

**Parameters:**
- `_owner`: Owner address
- `_vault`: BoringVault address
- `_balancerVault`: Balancer vault for flash loans

#### `setManageRoot(address strategist, bytes32 _manageRoot) external`
Sets the merkle root for a strategist.

**Parameters:**
- `strategist`: Strategist address
- `_manageRoot`: New merkle root

**Access Control:** OWNER_ROLE

#### `manageVaultWithMerkleVerification(bytes32[][] calldata manageProofs, address[] calldata decodersAndSanitizers, address[] calldata targets, bytes[] calldata targetData, uint256[] calldata values) external`
Executes multiple strategy calls with merkle verification.

**Parameters:**
- `manageProofs`: Array of merkle proofs for each call
- `decodersAndSanitizers`: Array of decoder contracts
- `targets`: Array of target addresses
- `targetData`: Array of calldata for each call
- `values`: Array of ETH values for each call

**Access Control:** MANAGER_INTERNAL_ROLE, STRATEGIST_ROLE, MICRO_MANAGER_ROLE

#### `flashLoan(address recipient, address[] calldata tokens, uint256[] calldata amounts, bytes calldata userData) external`
Initiates a flash loan.

**Parameters:**
- `recipient`: Address to receive the loan
- `tokens`: Array of tokens to borrow
- `amounts`: Array of amounts to borrow
- `userData`: Data to pass to the callback

**Access Control:** Only callable by BoringVault

#### `receiveFlashLoan(address[] calldata tokens, uint256[] calldata amounts, uint256[] calldata feeAmounts, bytes calldata userData) external`
Handles flash loan callback.

**Parameters:**
- `tokens`: Array of borrowed tokens
- `amounts`: Array of borrowed amounts
- `feeAmounts`: Array of fees owed
- `userData`: Data from the original call

**Access Control:** Only callable by Balancer vault

### Events

#### `ManageRootUpdated(address indexed strategist, bytes32 oldRoot, bytes32 newRoot)`
Emitted when a merkle root is updated.

#### `BoringVaultManaged(uint256 callsMade)`
Emitted when vault is managed.

## TellerWithMultiAssetSupport

### Overview
Handles user deposits and withdrawals with multi-asset support.

### Functions

#### `constructor(address _owner, address _vault, address _accountant, address _weth)`
Initializes the teller.

**Parameters:**
- `_owner`: Owner address
- `_vault`: BoringVault address
- `_accountant`: Accountant address
- `_weth`: WETH contract address

#### `updateAssetData(ERC20 asset, bool allowDeposits, bool allowWithdraws, uint16 sharePremium) external`
Updates asset configuration.

**Parameters:**
- `asset`: ERC20 token address
- `allowDeposits`: Whether deposits are allowed
- `allowWithdraws`: Whether withdrawals are allowed
- `sharePremium`: Premium to apply to shares (in basis points)

**Access Control:** OWNER_ROLE

#### `setShareLockPeriod(uint64 _shareLockPeriod) external`
Sets the share lock period.

**Parameters:**
- `_shareLockPeriod`: Lock period in seconds (max 3 days)

**Access Control:** OWNER_ROLE

#### `deposit(ERC20 depositAsset, uint256 depositAmount, uint256 minimumMint) external payable returns (uint256 shares)`
Deposits assets and mints shares.

**Parameters:**
- `depositAsset`: Asset to deposit (use NATIVE for ETH)
- `depositAmount`: Amount to deposit
- `minimumMint`: Minimum shares to receive

**Returns:**
- `shares`: Amount of shares minted

**Access Control:** Public (with auth check)

#### `depositWithPermit(ERC20 depositAsset, uint256 depositAmount, uint256 minimumMint, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (uint256 shares)`
Deposits using EIP-2612 permit.

**Parameters:**
- `depositAsset`: Asset to deposit
- `depositAmount`: Amount to deposit
- `minimumMint`: Minimum shares to receive
- `deadline`: Permit deadline
- `v`, `r`, `s`: Permit signature

**Returns:**
- `shares`: Amount of shares minted

**Access Control:** Public (with auth check)

#### `bulkDeposit(ERC20 depositAsset, uint256 depositAmount, uint256 minimumMint, address to) external returns (uint256 shares)`
Bulk deposit for solvers.

**Parameters:**
- `depositAsset`: Asset to deposit
- `depositAmount`: Amount to deposit
- `minimumMint`: Minimum shares to receive
- `to`: Address to mint shares to

**Returns:**
- `shares`: Amount of shares minted

**Access Control:** SOLVER_ROLE

#### `bulkWithdraw(ERC20 withdrawAsset, uint256 shareAmount, uint256 minimumAssets, address to) external returns (uint256 assetsOut)`
Bulk withdrawal for solvers.

**Parameters:**
- `withdrawAsset`: Asset to withdraw
- `shareAmount`: Shares to burn
- `minimumAssets`: Minimum assets to receive
- `to`: Address to send assets to

**Returns:**
- `assetsOut`: Amount of assets withdrawn

**Access Control:** SOLVER_ROLE

#### `refundDeposit(uint256 nonce, address receiver, address depositAsset, uint256 depositAmount, uint256 shareAmount, uint256 depositTimestamp, uint256 shareLockUpPeriodAtTimeOfDeposit) external`
Refunds a pending deposit.

**Parameters:**
- `nonce`: Deposit nonce
- `receiver`: Original depositor
- `depositAsset`: Asset that was deposited
- `depositAmount`: Amount that was deposited
- `shareAmount`: Shares that were minted
- `depositTimestamp`: When deposit was made
- `shareLockUpPeriodAtTimeOfDeposit`: Lock period at time of deposit

**Access Control:** STRATEGIST_MULTISIG_ROLE

### Events

#### `Deposit(uint256 indexed nonce, address indexed receiver, address indexed depositAsset, uint256 depositAmount, uint256 shareAmount, uint256 depositTimestamp, uint256 shareLockPeriodAtTimeOfDeposit)`
Emitted when a deposit is made.

#### `AssetDataUpdated(address indexed asset, bool allowDeposits, bool allowWithdraws, uint16 sharePremium)`
Emitted when asset data is updated.

## AccountantWithRateProviders

### Overview
Manages exchange rates and fee calculations.

### Functions

#### `constructor(address _owner, address _vault, address payoutAddress, uint96 startingExchangeRate, address _base, uint16 allowedExchangeRateChangeUpper, uint16 allowedExchangeRateChangeLower, uint24 minimumUpdateDelayInSeconds, uint16 platformFee, uint16 performanceFee)`
Initializes the accountant.

**Parameters:**
- `_owner`: Owner address
- `_vault`: BoringVault address
- `payoutAddress`: Address to receive fees
- `startingExchangeRate`: Initial exchange rate
- `_base`: Base asset for rates
- `allowedExchangeRateChangeUpper`: Max rate increase (basis points)
- `allowedExchangeRateChangeLower`: Max rate decrease (basis points)
- `minimumUpdateDelayInSeconds`: Min delay between updates
- `platformFee`: Platform fee (basis points)
- `performanceFee`: Performance fee (basis points)

#### `updateExchangeRate(uint96 newExchangeRate) external`
Updates the exchange rate.

**Parameters:**
- `newExchangeRate`: New exchange rate

**Access Control:** UPDATE_EXCHANGE_RATE_ROLE

#### `setRateProviderData(ERC20 asset, bool isPeggedToBase, address rateProvider) external`
Sets rate provider data for an asset.

**Parameters:**
- `asset`: Asset address
- `isPeggedToBase`: Whether asset is pegged to base
- `rateProvider`: Rate provider contract

**Access Control:** OWNER_ROLE

#### `claimFees(ERC20 feeAsset) external`
Claims pending fees.

**Parameters:**
- `feeAsset`: Asset to claim fees in

**Access Control:** Only callable by BoringVault

#### `getRate() public view returns (uint256 rate)`
Gets current exchange rate.

**Returns:**
- `rate`: Current exchange rate

#### `getRateSafe() external view returns (uint256 rate)`
Gets current exchange rate (reverts if paused).

**Returns:**
- `rate`: Current exchange rate

#### `getRateInQuote(ERC20 quote) public view returns (uint256 rateInQuote)`
Gets rate in terms of a quote asset.

**Parameters:**
- `quote`: Quote asset

**Returns:**
- `rateInQuote`: Rate in quote asset terms

### Events

#### `ExchangeRateUpdated(uint96 oldRate, uint96 newRate, uint64 currentTime)`
Emitted when exchange rate is updated.

#### `FeesClaimed(address indexed feeAsset, uint256 amount)`
Emitted when fees are claimed.

## AtomicQueue

### Overview
Enables atomic asset exchanges.

### Functions

#### `updateAtomicRequest(ERC20 offer, ERC20 want, AtomicRequest memory userRequest) external`
Updates a user's atomic request.

**Parameters:**
- `offer`: Asset to offer
- `want`: Asset wanted
- `userRequest`: Request details

**Access Control:** Public (with auth check)

#### `safeUpdateAtomicRequest(ERC20 offer, ERC20 want, AtomicRequest memory userRequest, AccountantWithRateProviders accountant, uint256 discount) external`
Updates atomic request with safety checks.

**Parameters:**
- `offer`: Asset to offer
- `want`: Asset wanted
- `userRequest`: Request details
- `accountant`: Accountant for rate calculation
- `discount`: Discount to apply

**Access Control:** Public (with auth check)

#### `solve(ERC20 offer, ERC20 want, address[] calldata users, bytes calldata runData, address solver) external`
Solves atomic requests.

**Parameters:**
- `offer`: Asset being offered
- `want`: Asset being wanted
- `users`: Array of users to solve for
- `runData`: Data for solver callback
- `solver`: Solver contract address

**Access Control:** SOLVER_ROLE

#### `viewSolveMetaData(ERC20 offer, ERC20 want, address[] calldata users) external view returns (SolveMetaData[] memory metaData, uint256 totalAssetsForWant, uint256 totalAssetsToOffer)`
Views solve metadata.

**Parameters:**
- `offer`: Asset being offered
- `want`: Asset being wanted
- `users`: Array of users to check

**Returns:**
- `metaData`: Array of user metadata
- `totalAssetsForWant`: Total assets needed
- `totalAssetsToOffer`: Total assets to offer

### Events

#### `AtomicRequestUpdated(address indexed user, address indexed offerToken, address indexed wantToken, uint256 amount, uint256 deadline, uint256 minPrice, uint256 timestamp)`
Emitted when atomic request is updated.

#### `AtomicRequestFulfilled(address indexed user, address indexed offerToken, address indexed wantToken, uint256 offerAmountSpent, uint256 wantAmountReceived, uint256 timestamp)`
Emitted when atomic request is fulfilled.

## Cross-Chain Components

### Overview
Components for cross-chain functionality.

### Key Contracts
- `CrossChainTellerWithGenericBridge`: Generic cross-chain teller
- `MessageLib`: Message handling utilities
- `CCIPBridgeIntegration`: Chainlink CCIP integration
- `LayerZeroTeller`: LayerZero integration

### Functions

#### `bridgeAssets(uint256 amount, uint16 destinationChain, bytes calldata data) external`
Bridges assets to another chain.

**Parameters:**
- `amount`: Amount to bridge
- `destinationChain`: Target chain ID
- `data`: Additional data

#### `receiveBridgedAssets(address asset, uint256 amount, address recipient) external`
Receives bridged assets.

**Parameters:**
- `asset`: Asset address
- `amount`: Amount received
- `recipient`: Recipient address

## Error Codes

### Common Errors
- `TellerWithMultiAssetSupport__AssetNotSupported()`: Asset not configured
- `TellerWithMultiAssetSupport__SharesAreLocked()`: Shares still locked
- `ManagerWithMerkleVerification__FailedToVerifyManageProof()`: Invalid merkle proof
- `AccountantWithRateProviders__Paused()`: Contract is paused
- `AtomicQueue__RequestDeadlineExceeded()`: Request deadline passed

## Usage Examples

### Basic Deposit
```solidity
// Deposit USDC
teller.deposit(USDC, 1000e6, 0);
```

### Deposit with Permit
```solidity
// Deposit with permit
teller.depositWithPermit(
    USDC,
    1000e6,
    0,
    deadline,
    v, r, s
);
```

### Strategy Execution
```solidity
// Execute strategy
manager.manageVaultWithMerkleVerification(
    proofs,
    decoders,
    targets,
    data,
    values
);
```

### Rate Update
```solidity
// Update exchange rate
accountant.updateExchangeRate(newRate);
```

### Atomic Request
```solidity
// Create atomic request
AtomicRequest memory request = AtomicRequest({
    deadline: block.timestamp + 1 days,
    atomicPrice: 1000e6,
    offerAmount: 1000e6,
    inSolve: false
});
atomicQueue.updateAtomicRequest(USDC, WETH, request);
```