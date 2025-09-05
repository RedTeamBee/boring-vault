// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IAuditLogger} from "src/interfaces/IAuditLogger.sol";
import {Auth, Authority} from "@solmate/auth/Auth.sol";

/**
 * @title AuditLogger
 * @notice Implementation of audit logging functionality for BoringVault
 * @dev Provides comprehensive logging of all critical vault operations for compliance and monitoring
 */
contract AuditLogger is IAuditLogger, Auth {
    // ========================================= STATE =========================================
    
    /// @notice Counter for generating unique operation IDs
    uint256 private _operationCounter;
    
    /// @notice Mapping from operation ID to management operations
    mapping(uint256 => ManagementOperation) private _managementOperations;
    
    /// @notice Mapping from operation ID to enter operations
    mapping(uint256 => EnterOperation) private _enterOperations;
    
    /// @notice Mapping from operation ID to exit operations
    mapping(uint256 => ExitOperation) private _exitOperations;
    
    /// @notice Mapping to track which operation type each ID represents
    /// @dev 1 = Management, 2 = Enter, 3 = Exit
    mapping(uint256 => uint8) private _operationTypes;
    
    // ========================================= CONSTANTS =========================================
    
    uint8 private constant MANAGEMENT_OPERATION = 1;
    uint8 private constant ENTER_OPERATION = 2;
    uint8 private constant EXIT_OPERATION = 3;
    
    // ========================================= CONSTRUCTOR =========================================
    
    /**
     * @notice Constructor for AuditLogger
     * @param _owner The owner of the contract (typically the BoringVault)
     */
    constructor(address _owner) Auth(_owner, Authority(address(0))) {
        // Start counter at 1 to avoid 0 as a valid operation ID
        _operationCounter = 1;
    }
    
    // ========================================= EXTERNAL FUNCTIONS =========================================
    
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
    ) external requiresAuth returns (uint256 operationId) {
        operationId = _operationCounter++;
        
        ManagementOperation memory operation = ManagementOperation({
            caller: caller,
            target: target,
            value: value,
            functionSelector: functionSelector,
            timestamp: block.timestamp,
            blockNumber: block.number
        });
        
        _managementOperations[operationId] = operation;
        _operationTypes[operationId] = MANAGEMENT_OPERATION;
        
        emit ManagementOperationLogged(operationId, operation);
    }
    
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
    ) external requiresAuth returns (uint256 operationId) {
        operationId = _operationCounter++;
        
        EnterOperation memory operation = EnterOperation({
            from: from,
            asset: asset,
            assetAmount: assetAmount,
            to: to,
            shareAmount: shareAmount,
            timestamp: block.timestamp,
            blockNumber: block.number
        });
        
        _enterOperations[operationId] = operation;
        _operationTypes[operationId] = ENTER_OPERATION;
        
        emit EnterOperationLogged(operationId, operation);
    }
    
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
    ) external requiresAuth returns (uint256 operationId) {
        operationId = _operationCounter++;
        
        ExitOperation memory operation = ExitOperation({
            to: to,
            asset: asset,
            assetAmount: assetAmount,
            from: from,
            shareAmount: shareAmount,
            timestamp: block.timestamp,
            blockNumber: block.number
        });
        
        _exitOperations[operationId] = operation;
        _operationTypes[operationId] = EXIT_OPERATION;
        
        emit ExitOperationLogged(operationId, operation);
    }
    
    // ========================================= VIEW FUNCTIONS =========================================
    
    /**
     * @notice Gets the total number of operations logged
     * @return The total number of operations
     */
    function getTotalOperations() external view returns (uint256) {
        return _operationCounter - 1; // Subtract 1 because counter starts at 1
    }
    
    /**
     * @notice Gets a management operation by ID
     * @param operationId The ID of the operation
     * @return The management operation details
     */
    function getManagementOperation(uint256 operationId) external view returns (ManagementOperation memory) {
        require(_operationTypes[operationId] == MANAGEMENT_OPERATION, "AuditLogger: Not a management operation");
        return _managementOperations[operationId];
    }
    
    /**
     * @notice Gets an enter operation by ID
     * @param operationId The ID of the operation
     * @return The enter operation details
     */
    function getEnterOperation(uint256 operationId) external view returns (EnterOperation memory) {
        require(_operationTypes[operationId] == ENTER_OPERATION, "AuditLogger: Not an enter operation");
        return _enterOperations[operationId];
    }
    
    /**
     * @notice Gets an exit operation by ID
     * @param operationId The ID of the operation
     * @return The exit operation details
     */
    function getExitOperation(uint256 operationId) external view returns (ExitOperation memory) {
        require(_operationTypes[operationId] == EXIT_OPERATION, "AuditLogger: Not an exit operation");
        return _exitOperations[operationId];
    }
    
    /**
     * @notice Gets the operation type for a given operation ID
     * @param operationId The ID of the operation
     * @return operationType The type of operation (1=Management, 2=Enter, 3=Exit, 0=Invalid)
     */
    function getOperationType(uint256 operationId) external view returns (uint8 operationType) {
        return _operationTypes[operationId];
    }
    
    /**
     * @notice Checks if an operation ID exists
     * @param operationId The ID to check
     * @return exists True if the operation exists, false otherwise
     */
    function operationExists(uint256 operationId) external view returns (bool exists) {
        return operationId > 0 && operationId < _operationCounter;
    }
}
