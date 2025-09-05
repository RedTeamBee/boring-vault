// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

/**
 * @title IAuditLogger
 * @notice Interface for audit logging functionality in BoringVault
 * @dev Provides structured logging of critical vault operations for compliance and monitoring
 */
interface IAuditLogger {
    // ========================================= STRUCTS =========================================
    
    /**
     * @notice Represents a management operation in the vault
     * @param caller The address that initiated the operation
     * @param target The target contract address
     * @param value The ETH value sent with the operation
     * @param functionSelector The function selector being called
     * @param timestamp The timestamp when the operation occurred
     * @param blockNumber The block number when the operation occurred
     */
    struct ManagementOperation {
        address caller;
        address target;
        uint256 value;
        bytes4 functionSelector;
        uint256 timestamp;
        uint256 blockNumber;
    }
    
    /**
     * @notice Represents an enter operation (minting shares)
     * @param from The address providing the assets
     * @param asset The asset being deposited
     * @param assetAmount The amount of assets deposited
     * @param to The address receiving the shares
     * @param shareAmount The amount of shares minted
     * @param timestamp The timestamp when the operation occurred
     * @param blockNumber The block number when the operation occurred
     */
    struct EnterOperation {
        address from;
        address asset;
        uint256 assetAmount;
        address to;
        uint256 shareAmount;
        uint256 timestamp;
        uint256 blockNumber;
    }
    
    /**
     * @notice Represents an exit operation (burning shares)
     * @param to The address receiving the assets
     * @param asset The asset being withdrawn
     * @param assetAmount The amount of assets withdrawn
     * @param from The address whose shares are burned
     * @param shareAmount The amount of shares burned
     * @param timestamp The timestamp when the operation occurred
     * @param blockNumber The block number when the operation occurred
     */
    struct ExitOperation {
        address to;
        address asset;
        uint256 assetAmount;
        address from;
        uint256 shareAmount;
        uint256 timestamp;
        uint256 blockNumber;
    }
    
    // ========================================= EVENTS =========================================
    
    /**
     * @notice Emitted when a management operation is logged
     * @param operationId The unique identifier for the operation
     * @param operation The management operation details
     */
    event ManagementOperationLogged(uint256 indexed operationId, ManagementOperation operation);
    
    /**
     * @notice Emitted when an enter operation is logged
     * @param operationId The unique identifier for the operation
     * @param operation The enter operation details
     */
    event EnterOperationLogged(uint256 indexed operationId, EnterOperation operation);
    
    /**
     * @notice Emitted when an exit operation is logged
     * @param operationId The unique identifier for the operation
     * @param operation The exit operation details
     */
    event ExitOperationLogged(uint256 indexed operationId, ExitOperation operation);
    
    // ========================================= FUNCTIONS =========================================
    
    /**
     * @notice Logs a management operation
     * @param caller The address that initiated the operation
     * @param target The target contract address
     * @param value The ETH value sent with the operation
     * @param functionSelector The function selector being called
     * @return operationId The unique identifier for the logged operation
     */
    function logManagementOperation(
        address caller,
        address target,
        uint256 value,
        bytes4 functionSelector
    ) external returns (uint256 operationId);
    
    /**
     * @notice Logs an enter operation
     * @param from The address providing the assets
     * @param asset The asset being deposited
     * @param assetAmount The amount of assets deposited
     * @param to The address receiving the shares
     * @param shareAmount The amount of shares minted
     * @return operationId The unique identifier for the logged operation
     */
    function logEnterOperation(
        address from,
        address asset,
        uint256 assetAmount,
        address to,
        uint256 shareAmount
    ) external returns (uint256 operationId);
    
    /**
     * @notice Logs an exit operation
     * @param to The address receiving the assets
     * @param asset The asset being withdrawn
     * @param assetAmount The amount of assets withdrawn
     * @param from The address whose shares are burned
     * @param shareAmount The amount of shares burned
     * @return operationId The unique identifier for the logged operation
     */
    function logExitOperation(
        address to,
        address asset,
        uint256 assetAmount,
        address from,
        uint256 shareAmount
    ) external returns (uint256 operationId);
    
    /**
     * @notice Gets the total number of operations logged
     * @return The total number of operations
     */
    function getTotalOperations() external view returns (uint256);
    
    /**
     * @notice Gets a management operation by ID
     * @param operationId The ID of the operation
     * @return The management operation details
     */
    function getManagementOperation(uint256 operationId) external view returns (ManagementOperation memory);
    
    /**
     * @notice Gets an enter operation by ID
     * @param operationId The ID of the operation
     * @return The enter operation details
     */
    function getEnterOperation(uint256 operationId) external view returns (EnterOperation memory);
    
    /**
     * @notice Gets an exit operation by ID
     * @param operationId The ID of the operation
     * @return The exit operation details
     */
    function getExitOperation(uint256 operationId) external view returns (ExitOperation memory);
}
