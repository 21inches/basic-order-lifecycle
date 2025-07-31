// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

type Address is uint256;

/**
* @notice AddressLib
* @notice Library for working with addresses encoded as uint256 values, which can include flags in the highest bits.
*/
library AddressLib {
    uint256 private constant _LOW_160_BIT_MASK = (1 << 160) - 1;

    /**
    * @notice Returns the address representation of a uint256.
    * @param a The uint256 value to convert to an address.
    * @return The address representation of the provided uint256 value.
    */
    function get(Address a) internal pure returns (address) {
        return address(uint160(Address.unwrap(a) & _LOW_160_BIT_MASK));
    }

    /**
    * @notice Checks if a given flag is set for the provided address.
    * @param a The address to check for the flag.
    * @param flag The flag to check for in the provided address.
    * @return True if the provided flag is set in the address, false otherwise.
    */
    function getFlag(Address a, uint256 flag) internal pure returns (bool) {
        return (Address.unwrap(a) & flag) != 0;
    }

    /**
    * @notice Returns a uint32 value stored at a specific bit offset in the provided address.
    * @param a The address containing the uint32 value.
    * @param offset The bit offset at which the uint32 value is stored.
    * @return The uint32 value stored in the address at the specified bit offset.
    */
    function getUint32(Address a, uint256 offset) internal pure returns (uint32) {
        return uint32(Address.unwrap(a) >> offset);
    }

    /**
    * @notice Returns a uint64 value stored at a specific bit offset in the provided address.
    * @param a The address containing the uint64 value.
    * @param offset The bit offset at which the uint64 value is stored.
    * @return The uint64 value stored in the address at the specified bit offset.
    */
    function getUint64(Address a, uint256 offset) internal pure returns (uint64) {
        return uint64(Address.unwrap(a) >> offset);
    }
}

type MakerTraits is uint256;

/**
 * @title MakerTraitsLib
 * @notice A library to manage and check MakerTraits, which are used to encode the maker's preferences for an order in a single uint256.
 * @dev
 * The MakerTraits type is a uint256 and different parts of the number are used to encode different traits.
 * High bits are used for flags
 * 255 bit `NO_PARTIAL_FILLS_FLAG`          - if set, the order does not allow partial fills
 * 254 bit `ALLOW_MULTIPLE_FILLS_FLAG`      - if set, the order permits multiple fills
 * 253 bit                                  - unused
 * 252 bit `PRE_INTERACTION_CALL_FLAG`      - if set, the order requires pre-interaction call
 * 251 bit `POST_INTERACTION_CALL_FLAG`     - if set, the order requires post-interaction call
 * 250 bit `NEED_CHECK_EPOCH_MANAGER_FLAG`  - if set, the order requires to check the epoch manager
 * 249 bit `HAS_EXTENSION_FLAG`             - if set, the order has extension(s)
 * 248 bit `USE_PERMIT2_FLAG`               - if set, the order uses permit2
 * 247 bit `UNWRAP_WETH_FLAG`               - if set, the order requires to unwrap WETH

 * Low 200 bits are used for allowed sender, expiration, nonceOrEpoch, and series
 * uint80 last 10 bytes of allowed sender address (0 if any)
 * uint40 expiration timestamp (0 if none)
 * uint40 nonce or epoch
 * uint40 series
 */
library MakerTraitsLib {
    // Low 200 bits are used for allowed sender, expiration, nonceOrEpoch, and series
    uint256 private constant _ALLOWED_SENDER_MASK = type(uint80).max;
    uint256 private constant _EXPIRATION_OFFSET = 80;
    uint256 private constant _EXPIRATION_MASK = type(uint40).max;
    uint256 private constant _NONCE_OR_EPOCH_OFFSET = 120;
    uint256 private constant _NONCE_OR_EPOCH_MASK = type(uint40).max;
    uint256 private constant _SERIES_OFFSET = 160;
    uint256 private constant _SERIES_MASK = type(uint40).max;

    uint256 private constant _NO_PARTIAL_FILLS_FLAG = 1 << 255;
    uint256 private constant _ALLOW_MULTIPLE_FILLS_FLAG = 1 << 254;
    uint256 private constant _PRE_INTERACTION_CALL_FLAG = 1 << 252;
    uint256 private constant _POST_INTERACTION_CALL_FLAG = 1 << 251;
    uint256 private constant _NEED_CHECK_EPOCH_MANAGER_FLAG = 1 << 250;
    uint256 private constant _HAS_EXTENSION_FLAG = 1 << 249;
    uint256 private constant _USE_PERMIT2_FLAG = 1 << 248;
    uint256 private constant _UNWRAP_WETH_FLAG = 1 << 247;

    /**
     * @notice Checks if the order has the extension flag set.
     * @dev If the `HAS_EXTENSION_FLAG` is set in the makerTraits, then the protocol expects that the order has extension(s).
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the flag is set.
     */
    function hasExtension(MakerTraits makerTraits) internal pure returns (bool) {
        return (MakerTraits.unwrap(makerTraits) & _HAS_EXTENSION_FLAG) != 0;
    }

    /**
     * @notice Checks if the maker allows a specific taker to fill the order.
     * @param makerTraits The traits of the maker.
     * @param sender The address of the taker to be checked.
     * @return result A boolean indicating whether the taker is allowed.
     */
    function isAllowedSender(MakerTraits makerTraits, address sender) internal pure returns (bool) {
        uint160 allowedSender = uint160(MakerTraits.unwrap(makerTraits) & _ALLOWED_SENDER_MASK);
        return allowedSender == 0 || allowedSender == uint160(sender) & _ALLOWED_SENDER_MASK;
    }

    /**
     * @notice Returns the expiration time of the order.
     * @param makerTraits The traits of the maker.
     * @return result The expiration timestamp of the order.
     */
    function getExpirationTime(MakerTraits makerTraits) internal pure returns (uint256) {
        return (MakerTraits.unwrap(makerTraits) >> _EXPIRATION_OFFSET) & _EXPIRATION_MASK;
    }

    /**
     * @notice Checks if the order has expired.
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the order has expired.
     */
    function isExpired(MakerTraits makerTraits) internal view returns (bool) {
        uint256 expiration = getExpirationTime(makerTraits);
        return expiration != 0 && expiration < block.timestamp;  // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Returns the nonce or epoch of the order.
     * @param makerTraits The traits of the maker.
     * @return result The nonce or epoch of the order.
     */
    function nonceOrEpoch(MakerTraits makerTraits) internal pure returns (uint256) {
        return (MakerTraits.unwrap(makerTraits) >> _NONCE_OR_EPOCH_OFFSET) & _NONCE_OR_EPOCH_MASK;
    }

    /**
     * @notice Returns the series of the order.
     * @param makerTraits The traits of the maker.
     * @return result The series of the order.
     */
    function series(MakerTraits makerTraits) internal pure returns (uint256) {
        return (MakerTraits.unwrap(makerTraits) >> _SERIES_OFFSET) & _SERIES_MASK;
    }

    /**
      * @notice Determines if the order allows partial fills.
      * @dev If the _NO_PARTIAL_FILLS_FLAG is not set in the makerTraits, then the order allows partial fills.
      * @param makerTraits The traits of the maker, determining their preferences for the order.
      * @return result A boolean indicating whether the maker allows partial fills.
      */
    function allowPartialFills(MakerTraits makerTraits) internal pure returns (bool) {
        return (MakerTraits.unwrap(makerTraits) & _NO_PARTIAL_FILLS_FLAG) == 0;
    }

    /**
     * @notice Checks if the maker needs pre-interaction call.
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the maker needs a pre-interaction call.
     */
    function needPreInteractionCall(MakerTraits makerTraits) internal pure returns (bool) {
        return (MakerTraits.unwrap(makerTraits) & _PRE_INTERACTION_CALL_FLAG) != 0;
    }

    /**
     * @notice Checks if the maker needs post-interaction call.
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the maker needs a post-interaction call.
     */
    function needPostInteractionCall(MakerTraits makerTraits) internal pure returns (bool) {
        return (MakerTraits.unwrap(makerTraits) & _POST_INTERACTION_CALL_FLAG) != 0;
    }

    /**
      * @notice Determines if the order allows multiple fills.
      * @dev If the _ALLOW_MULTIPLE_FILLS_FLAG is set in the makerTraits, then the maker allows multiple fills.
      * @param makerTraits The traits of the maker, determining their preferences for the order.
      * @return result A boolean indicating whether the maker allows multiple fills.
      */
    function allowMultipleFills(MakerTraits makerTraits) internal pure returns (bool) {
        return (MakerTraits.unwrap(makerTraits) & _ALLOW_MULTIPLE_FILLS_FLAG) != 0;
    }

    /**
      * @notice Determines if an order should use the bit invalidator or remaining amount validator.
      * @dev The bit invalidator can be used if the order does not allow partial or multiple fills.
      * @param makerTraits The traits of the maker, determining their preferences for the order.
      * @return result A boolean indicating whether the bit invalidator should be used.
      * True if the order requires the use of the bit invalidator.
      */
    function useBitInvalidator(MakerTraits makerTraits) internal pure returns (bool) {
        return !allowPartialFills(makerTraits) || !allowMultipleFills(makerTraits);
    }

    /**
     * @notice Checks if the maker needs to check the epoch.
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the maker needs to check the epoch manager.
     */
    function needCheckEpochManager(MakerTraits makerTraits) internal pure returns (bool) {
        return (MakerTraits.unwrap(makerTraits) & _NEED_CHECK_EPOCH_MANAGER_FLAG) != 0;
    }

    /**
     * @notice Checks if the maker uses permit2.
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the maker uses permit2.
     */
    function usePermit2(MakerTraits makerTraits) internal pure returns (bool) {
        return MakerTraits.unwrap(makerTraits) & _USE_PERMIT2_FLAG != 0;
    }

    /**
     * @notice Checks if the maker needs to unwraps WETH.
     * @param makerTraits The traits of the maker.
     * @return result A boolean indicating whether the maker needs to unwrap WETH.
     */
    function unwrapWeth(MakerTraits makerTraits) internal pure returns (bool) {
        return MakerTraits.unwrap(makerTraits) & _UNWRAP_WETH_FLAG != 0;
    }
}

type TakerTraits is uint256;

/**
 * @title TakerTraitsLib
 * @notice This library to manage and check TakerTraits, which are used to encode the taker's preferences for an order in a single uint256.
 * @dev The TakerTraits are structured as follows:
 * High bits are used for flags
 * 255 bit `_MAKER_AMOUNT_FLAG`           - If set, the taking amount is calculated based on making amount, otherwise making amount is calculated based on taking amount.
 * 254 bit `_UNWRAP_WETH_FLAG`            - If set, the WETH will be unwrapped into ETH before sending to taker.
 * 253 bit `_SKIP_ORDER_PERMIT_FLAG`      - If set, the order skips maker's permit execution.
 * 252 bit `_USE_PERMIT2_FLAG`            - If set, the order uses the permit2 function for authorization.
 * 251 bit `_ARGS_HAS_TARGET`             - If set, then first 20 bytes of args are treated as target address for maker’s funds transfer.
 * 224-247 bits `ARGS_EXTENSION_LENGTH`   - The length of the extension calldata in the args.
 * 200-223 bits `ARGS_INTERACTION_LENGTH` - The length of the interaction calldata in the args.
 * 0-184 bits                             - The threshold amount (the maximum amount a taker agrees to give in exchange for a making amount).
 */
library TakerTraitsLib {
    uint256 private constant _MAKER_AMOUNT_FLAG = 1 << 255;
    uint256 private constant _UNWRAP_WETH_FLAG = 1 << 254;
    uint256 private constant _SKIP_ORDER_PERMIT_FLAG = 1 << 253;
    uint256 private constant _USE_PERMIT2_FLAG = 1 << 252;
    uint256 private constant _ARGS_HAS_TARGET = 1 << 251;

    uint256 private constant _ARGS_EXTENSION_LENGTH_OFFSET = 224;
    uint256 private constant _ARGS_EXTENSION_LENGTH_MASK = 0xffffff;
    uint256 private constant _ARGS_INTERACTION_LENGTH_OFFSET = 200;
    uint256 private constant _ARGS_INTERACTION_LENGTH_MASK = 0xffffff;

    uint256 private constant _AMOUNT_MASK = 0x000000000000000000ffffffffffffffffffffffffffffffffffffffffffffff;

    /**
     * @notice Checks if the args should contain target address.
     * @param takerTraits The traits of the taker.
     * @return result A boolean indicating whether the args should contain target address.
     */
    function argsHasTarget(TakerTraits takerTraits) internal pure returns (bool) {
        return (TakerTraits.unwrap(takerTraits) & _ARGS_HAS_TARGET) != 0;
    }

    /**
     * @notice Retrieves the length of the extension calldata from the takerTraits.
     * @param takerTraits The traits of the taker.
     * @return result The length of the extension calldata encoded in the takerTraits.
     */
    function argsExtensionLength(TakerTraits takerTraits) internal pure returns (uint256) {
        return (TakerTraits.unwrap(takerTraits) >> _ARGS_EXTENSION_LENGTH_OFFSET) & _ARGS_EXTENSION_LENGTH_MASK;
    }

    /**
     * @notice Retrieves the length of the interaction calldata from the takerTraits.
     * @param takerTraits The traits of the taker.
     * @return result The length of the interaction calldata encoded in the takerTraits.
     */
    function argsInteractionLength(TakerTraits takerTraits) internal pure returns (uint256) {
        return (TakerTraits.unwrap(takerTraits) >> _ARGS_INTERACTION_LENGTH_OFFSET) & _ARGS_INTERACTION_LENGTH_MASK;
    }

    /**
     * @notice Checks if the taking amount should be calculated based on making amount.
     * @param takerTraits The traits of the taker.
     * @return result A boolean indicating whether the taking amount should be calculated based on making amount.
     */
    function isMakingAmount(TakerTraits takerTraits) internal pure returns (bool) {
        return (TakerTraits.unwrap(takerTraits) & _MAKER_AMOUNT_FLAG) != 0;
    }

    /**
     * @notice Checks if the order should unwrap WETH and send ETH to taker.
     * @param takerTraits The traits of the taker.
     * @return result A boolean indicating whether the order should unwrap WETH.
     */
    function unwrapWeth(TakerTraits takerTraits) internal pure returns (bool) {
        return (TakerTraits.unwrap(takerTraits) & _UNWRAP_WETH_FLAG) != 0;
    }

    /**
     * @notice Checks if the order should skip maker's permit execution.
     * @param takerTraits The traits of the taker.
     * @return result A boolean indicating whether the order don't apply permit.
     */
    function skipMakerPermit(TakerTraits takerTraits) internal pure returns (bool) {
        return (TakerTraits.unwrap(takerTraits) & _SKIP_ORDER_PERMIT_FLAG) != 0;
    }

    /**
     * @notice Checks if the order uses the permit2 instead of permit.
     * @param takerTraits The traits of the taker.
     * @return result A boolean indicating whether the order uses the permit2.
     */
    function usePermit2(TakerTraits takerTraits) internal pure returns (bool) {
        return (TakerTraits.unwrap(takerTraits) & _USE_PERMIT2_FLAG) != 0;
    }

    /**
     * @notice Retrieves the threshold amount from the takerTraits.
     * The maximum amount a taker agrees to give in exchange for a making amount.
     * @param takerTraits The traits of the taker.
     * @return result The threshold amount encoded in the takerTraits.
     */
    function threshold(TakerTraits takerTraits) internal pure returns (uint256) {
        return TakerTraits.unwrap(takerTraits) & _AMOUNT_MASK;
    }
}


/**
 * @title IOrderMixin
 * @notice Interface for order processing logic in the 1inch Limit Order Protocol.
 */
interface IOrderMixin {
    struct Order {
        uint256 salt;
        Address maker;
        Address receiver;
        Address makerAsset;
        Address takerAsset;
        uint256 makingAmount;
        uint256 takingAmount;
        MakerTraits makerTraits;
    }

    error InvalidatedOrder();
    error TakingAmountExceeded();
    error PrivateOrder();
    error BadSignature();
    error OrderExpired();
    error WrongSeriesNonce();
    error SwapWithZeroAmount();
    error PartialFillNotAllowed();
    error OrderIsNotSuitableForMassInvalidation();
    error EpochManagerAndBitInvalidatorsAreIncompatible();
    error ReentrancyDetected();
    error PredicateIsNotTrue();
    error TakingAmountTooHigh();
    error MakingAmountTooLow();
    error TransferFromMakerToTakerFailed();
    error TransferFromTakerToMakerFailed();
    error MismatchArraysLengths();
    error InvalidPermit2Transfer();
    error SimulationResults(bool success, bytes res);

    /**
     * @notice Emitted when order gets filled
     * @param orderHash Hash of the order
     * @param remainingAmount Amount of the maker asset that remains to be filled
     */
    event OrderFilled(
        bytes32 orderHash,
        uint256 remainingAmount
    );

    /**
     * @notice Emitted when order without `useBitInvalidator` gets cancelled
     * @param orderHash Hash of the order
     */
    event OrderCancelled(
        bytes32 orderHash
    );

    /**
     * @notice Emitted when order with `useBitInvalidator` gets cancelled
     * @param maker Maker address
     * @param slotIndex Slot index that was updated
     * @param slotValue New slot value
     */
    event BitInvalidatorUpdated(
        address indexed maker,
        uint256 slotIndex,
        uint256 slotValue
    );

    /**
     * @notice Delegates execution to custom implementation. Could be used to validate if `transferFrom` works properly
     * @dev The function always reverts and returns the simulation results in revert data.
     * @param target Addresses that will be delegated
     * @param data Data that will be passed to delegatee
     */
    function simulate(address target, bytes calldata data) external;

    /**
     * @notice Cancels order's quote
     * @param makerTraits Order makerTraits
     * @param orderHash Hash of the order to cancel
     */
    function cancelOrder(MakerTraits makerTraits, bytes32 orderHash) external;

    /**
     * @notice Cancels orders' quotes
     * @param makerTraits Orders makerTraits
     * @param orderHashes Hashes of the orders to cancel
     */
    function cancelOrders(MakerTraits[] calldata makerTraits, bytes32[] calldata orderHashes) external;

    /**
     * @notice Cancels all quotes of the maker (works for bit-invalidating orders only)
     * @param makerTraits Order makerTraits
     * @param additionalMask Additional bitmask to invalidate orders
     */
    function bitsInvalidateForOrder(MakerTraits makerTraits, uint256 additionalMask) external;

    /**
     * @notice Fills order's quote, fully or partially (whichever is possible).
     * @param order Order quote to fill
     * @param r R component of signature
     * @param vs VS component of signature
     * @param amount Taker amount to fill
     * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
     * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
     * @return makingAmount Actual amount transferred from maker to taker
     * @return takingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrder(
        Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits
    ) external payable returns(uint256 makingAmount, uint256 takingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillOrder` but allows to specify arguments that are used by the taker.
     * @param order Order quote to fill
     * @param r R component of signature
     * @param vs VS component of signature
     * @param amount Taker amount to fill
     * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
     * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
     * @param args Arguments that are used by the taker (target, extension, interaction, permit)
     * @return makingAmount Actual amount transferred from maker to taker
     * @return takingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderArgs(
        IOrderMixin.Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    ) external payable returns(uint256 makingAmount, uint256 takingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillOrder` but uses contract-based signatures.
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param amount Taker amount to fill
     * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
     * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
     * @return makingAmount Actual amount transferred from maker to taker
     * @return takingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     * @dev See tests for examples
     */
    function fillContractOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 amount,
        TakerTraits takerTraits
    ) external returns(uint256 makingAmount, uint256 takingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillContractOrder` but allows to specify arguments that are used by the taker.
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param amount Taker amount to fill
     * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
     * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
     * @param args Arguments that are used by the taker (target, extension, interaction, permit)
     * @return makingAmount Actual amount transferred from maker to taker
     * @return takingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     * @dev See tests for examples
     */
    function fillContractOrderArgs(
        Order calldata order,
        bytes calldata signature,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    ) external returns(uint256 makingAmount, uint256 takingAmount, bytes32 orderHash);

    /**
     * @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
     * @param maker Maker address
     * @param slot Slot number to return bitmask for
     * @return result Each bit represents whether corresponding was already invalidated
     */
    function bitInvalidatorForOrder(address maker, uint256 slot) external view returns(uint256 result);

    /**
     * @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
     * @param orderHash Hash of the order
     * @return remaining Remaining amount of the order
     */
    function remainingInvalidatorForOrder(address maker, bytes32 orderHash) external view returns(uint256 remaining);

    /**
     * @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
     * @param orderHash Hash of the order
     * @return remainingRaw Inverse of the remaining amount of the order if order was filled at least once, otherwise 0
     */
    function rawRemainingInvalidatorForOrder(address maker, bytes32 orderHash) external view returns(uint256 remainingRaw);

    /**
     * @notice Returns order hash, hashed with limit order protocol contract EIP712
     * @param order Order
     * @return orderHash Hash of the order
     */
    function hashOrder(IOrderMixin.Order calldata order) external view returns(bytes32 orderHash);
}


/**
 * @dev Timelocks for the source and the destination chains plus the deployment timestamp.
 * Timelocks store the number of seconds from the time the contract is deployed to the start of a specific period.
 * For illustrative purposes, it is possible to describe timelocks by two structures:
 * struct SrcTimelocks {
 *     uint256 withdrawal;
 *     uint256 publicWithdrawal;
 *     uint256 cancellation;
 *     uint256 publicCancellation;
 * }
 *
 * struct DstTimelocks {
 *     uint256 withdrawal;
 *     uint256 publicWithdrawal;
 *     uint256 cancellation;
 * }
 *
 * withdrawal: Period when only the taker with a secret can withdraw tokens for taker (source chain) or maker (destination chain).
 * publicWithdrawal: Period when anyone with a secret can withdraw tokens for taker (source chain) or maker (destination chain).
 * cancellation: Period when escrow can only be cancelled by the taker.
 * publicCancellation: Period when escrow can be cancelled by anyone.
 *
 * @custom:security-contact security@1inch.io
 */
type Timelocks is uint256;

/**
 * @title Timelocks library for compact storage of timelocks in a uint256.
 */
library TimelocksLib {
    enum Stage {
        SrcWithdrawal,
        SrcPublicWithdrawal,
        SrcCancellation,
        SrcPublicCancellation,
        DstWithdrawal,
        DstPublicWithdrawal,
        DstCancellation
    }

    uint256 private constant _DEPLOYED_AT_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;
    uint256 private constant _DEPLOYED_AT_OFFSET = 224;

    /**
     * @notice Sets the Escrow deployment timestamp.
     * @param timelocks The timelocks to set the deployment timestamp to.
     * @param value The new Escrow deployment timestamp.
     * @return The timelocks with the deployment timestamp set.
     */
    function setDeployedAt(Timelocks timelocks, uint256 value) internal pure returns (Timelocks) {
        return Timelocks.wrap((Timelocks.unwrap(timelocks) & ~uint256(_DEPLOYED_AT_MASK)) | value << _DEPLOYED_AT_OFFSET);
    }

    /**
     * @notice Returns the start of the rescue period.
     * @param timelocks The timelocks to get the rescue delay from.
     * @return The start of the rescue period.
     */
    function rescueStart(Timelocks timelocks, uint256 rescueDelay) internal pure returns (uint256) {
        unchecked {
            return rescueDelay + (Timelocks.unwrap(timelocks) >> _DEPLOYED_AT_OFFSET);
        }
    }

    /**
     * @notice Returns the timelock value for the given stage.
     * @param timelocks The timelocks to get the value from.
     * @param stage The stage to get the value for.
     * @return The timelock value for the given stage.
     */
    function get(Timelocks timelocks, Stage stage) internal pure returns (uint256) {
        uint256 data = Timelocks.unwrap(timelocks);
        uint256 bitShift = uint256(stage) * 32;
        // The maximum uint32 value will be reached in 2106.
        return (data >> _DEPLOYED_AT_OFFSET) + uint32(data >> bitShift);
    }
}


/**
 * @title Base Escrow interface for cross-chain atomic swap.
 * @notice Interface implies locking funds initially and then unlocking them with verification of the secret presented.
 * @custom:security-contact security@1inch.io
 */
interface IBaseEscrow {
    struct Immutables {
        bytes32 orderHash;
        bytes32 hashlock;  // Hash of the secret.
        Address maker;
        Address taker;
        Address token;
        uint256 amount;
        uint256 safetyDeposit;
        Timelocks timelocks;
    }

    /**
     * @notice Emitted on escrow cancellation.
     */
    event EscrowCancelled();

    /**
     * @notice Emitted when funds are rescued.
     * @param token The address of the token rescued. Zero address for native token.
     * @param amount The amount of tokens rescued.
     */
    event FundsRescued(address token, uint256 amount);

    /**
     * @notice Emitted on successful withdrawal.
     * @param secret The secret that unlocks the escrow.
     */
    event EscrowWithdrawal(bytes32 secret);

    error InvalidCaller();
    error InvalidImmutables();
    error InvalidSecret();
    error InvalidTime();
    error NativeTokenSendingFailure();

    /* solhint-disable func-name-mixedcase */
    /// @notice Returns the delay for rescuing funds from the escrow.
    function RESCUE_DELAY() external view returns (uint256);
    /// @notice Returns the address of the factory that created the escrow.
    function FACTORY() external view returns (address);
    /* solhint-enable func-name-mixedcase */

    /**
     * @notice Withdraws funds to a predetermined recipient.
     * @dev Withdrawal can only be made during the withdrawal period and with secret with hash matches the hashlock.
     * The safety deposit is sent to the caller.
     * @param secret The secret that unlocks the escrow.
     * @param immutables The immutables of the escrow contract.
     */
    function withdraw(bytes32 secret, Immutables calldata immutables) external;

    /**
     * @notice Cancels the escrow and returns tokens to a predetermined recipient.
     * @dev The escrow can only be cancelled during the cancellation period.
     * The safety deposit is sent to the caller.
     * @param immutables The immutables of the escrow contract.
     */
    function cancel(Immutables calldata immutables) external;

    /**
     * @notice Rescues funds from the escrow.
     * @dev Funds can only be rescued by the taker after the rescue delay.
     * @param token The address of the token to rescue. Zero address for native token.
     * @param amount The amount of tokens to rescue.
     * @param immutables The immutables of the escrow contract.
     */
    function rescueFunds(address token, uint256 amount, Immutables calldata immutables) external;
}


/**
 * @title Interface for the sample implementation of a Resolver contract for cross-chain swap.
 * @custom:security-contact security@1inch.io
 */
interface IResolverExample {
    error InvalidLength();
    error LengthMismatch();

    /**
     * @notice Deploys a new escrow contract for maker on the source chain.
     * @param immutables The immutables of the escrow contract that are used in deployment.
     * @param order Order quote to fill.
     * @param r R component of signature.
     * @param vs VS component of signature.
     * @param amount Taker amount to fill
     * @param takerTraits Specifies threshold as maximum allowed takingAmount when takingAmount is zero, otherwise specifies
     * minimum allowed makingAmount. The 2nd (0 based index) highest bit specifies whether taker wants to skip maker's permit.
     * @param args Arguments that are used by the taker (target, extension, interaction, permit).
     */
    function deploySrc(
        IBaseEscrow.Immutables calldata immutables,
        IOrderMixin.Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    ) external;

    /**
     * @notice Deploys a new escrow contract for taker on the destination chain.
     * @param dstImmutables The immutables of the escrow contract that are used in deployment.
     * @param srcCancellationTimestamp The start of the cancellation period for the source chain.
     */
    function deployDst(IBaseEscrow.Immutables calldata dstImmutables, uint256 srcCancellationTimestamp) external payable;

    /**
     * @notice Allows the owner to make arbitrary calls to other contracts on behalf of this contract.
     * @param targets The addresses of the contracts to call.
     * @param arguments The arguments to pass to the contract calls.
     */
    function arbitraryCalls(address[] calldata targets, bytes[] calldata arguments) external;
}

/**
 * @title RevertReasonForwarder
 * @notice Provides utilities for forwarding and retrieving revert reasons from failed external calls.
 */
library RevertReasonForwarder {
    /**
     * @dev Forwards the revert reason from the latest external call.
     * This method allows propagating the revert reason of a failed external call to the caller.
     */
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }

    /**
     * @dev Retrieves the revert reason from the latest external call.
     * This method enables capturing the revert reason of a failed external call for inspection or processing.
     * @return reason The latest external call revert reason.
     */
    function reReason() internal pure returns (bytes memory reason) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            reason := mload(0x40)
            let length := returndatasize()
            mstore(reason, length)
            returndatacopy(add(reason, 0x20), 0, length)
            mstore(0x40, add(reason, add(0x20, length)))
        }
    }
}

/**
 * @title Escrow Factory interface for cross-chain atomic swap.
 * @notice Interface to deploy escrow contracts for the destination chain and to get the deterministic address of escrow on both chains.
 * @custom:security-contact security@1inch.io
 */
interface IEscrowFactory {
    struct ExtraDataArgs {
        bytes32 hashlockInfo; // Hash of the secret or the Merkle tree root if multiple fills are allowed
        uint256 dstChainId;
        Address dstToken;
        uint256 deposits;
        Timelocks timelocks;
    }

    struct DstImmutablesComplement {
        Address maker;
        uint256 amount;
        Address token;
        uint256 safetyDeposit;
        uint256 chainId;
    }

    error InsufficientEscrowBalance();
    error InvalidCreationTime();
    error InvalidPartialFill();
    error InvalidSecretsAmount();

    /**
     * @notice Emitted on EscrowSrc deployment to recreate EscrowSrc and EscrowDst immutables off-chain.
     * @param srcImmutables The immutables of the escrow contract that are used in deployment on the source chain.
     * @param dstImmutablesComplement Additional immutables related to the escrow contract on the destination chain.
     */
    event SrcEscrowCreated(IBaseEscrow.Immutables srcImmutables, DstImmutablesComplement dstImmutablesComplement);
    /**
     * @notice Emitted on EscrowDst deployment.
     * @param escrow The address of the created escrow.
     * @param hashlock The hash of the secret.
     * @param taker The address of the taker.
     */
    event DstEscrowCreated(address escrow, bytes32 hashlock, Address taker);

    /* solhint-disable func-name-mixedcase */
    /// @notice Returns the address of implementation on the source chain.
    function ESCROW_SRC_IMPLEMENTATION() external view returns (address);
    /// @notice Returns the address of implementation on the destination chain.
    function ESCROW_DST_IMPLEMENTATION() external view returns (address);
    /* solhint-enable func-name-mixedcase */

    /**
     * @notice Creates a new escrow contract for taker on the destination chain.
     * @dev The caller must send the safety deposit in the native token along with the function call
     * and approve the destination token to be transferred to the created escrow.
     * @param dstImmutables The immutables of the escrow contract that are used in deployment.
     * @param srcCancellationTimestamp The start of the cancellation period for the source chain.
     */
    function createDstEscrow(IBaseEscrow.Immutables calldata dstImmutables, uint256 srcCancellationTimestamp) external payable;

    /**
     * @notice Returns the deterministic address of the source escrow based on the salt.
     * @param immutables The immutable arguments used to compute salt for escrow deployment.
     * @return The computed address of the escrow.
     */
    function addressOfEscrowSrc(IBaseEscrow.Immutables calldata immutables) external view returns (address);

    /**
     * @notice Returns the deterministic address of the destination escrow based on the salt.
     * @param immutables The immutable arguments used to compute salt for escrow deployment.
     * @return The computed address of the escrow.
     */
    function addressOfEscrowDst(IBaseEscrow.Immutables calldata immutables) external view returns (address);
}

/**
 * @title Escrow interface for cross-chain atomic swap.
 * @notice Interface implies locking funds initially and then unlocking them with verification of the secret presented.
 * @custom:security-contact security@1inch.io
 */
interface IEscrow is IBaseEscrow {
    /// @notice Returns the bytecode hash of the proxy contract.
    function PROXY_BYTECODE_HASH() external view returns (bytes32); // solhint-disable-line func-name-mixedcase
}

/**
 * @title Library for escrow immutables.
 * @custom:security-contact security@1inch.io
 */
library ImmutablesLib {
    uint256 internal constant ESCROW_IMMUTABLES_SIZE = 0x100;

    /**
     * @notice Returns the hash of the immutables.
     * @param immutables The immutables to hash.
     * @return ret The computed hash.
     */
    function hash(IBaseEscrow.Immutables calldata immutables) internal pure returns(bytes32 ret) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, immutables, ESCROW_IMMUTABLES_SIZE)
            ret := keccak256(ptr, ESCROW_IMMUTABLES_SIZE)
        }
    }

    /**
     * @notice Returns the hash of the immutables.
     * @param immutables The immutables to hash.
     * @return ret The computed hash.
     */
    function hashMem(IBaseEscrow.Immutables memory immutables) internal pure returns(bytes32 ret) {
        assembly ("memory-safe") {
            ret := keccak256(immutables, ESCROW_IMMUTABLES_SIZE)
        }
    }
}

/**
 * @title Sample implementation of a Resolver contract for cross-chain swap.
 * @dev It is important when deploying an escrow on the source chain to send the safety deposit and deploy the escrow in the same
 * transaction, since the address of the escrow depends on the block.timestamp.
 * You can find sample code for this in the {ResolverExample-deploySrc}.
 *
 * @custom:security-contact security@1inch.io
 */
contract Resolver is Ownable {
    using ImmutablesLib for IBaseEscrow.Immutables;
    using TimelocksLib for Timelocks;

    error InvalidLength();
    error LengthMismatch();

    IEscrowFactory private immutable _FACTORY;
    IOrderMixin private immutable _LOP;

    constructor(IEscrowFactory factory, IOrderMixin lop, address initialOwner) Ownable(initialOwner) {
        _FACTORY = factory;
        _LOP = lop;
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks

    /**
     * @notice See {IResolverExample-deploySrc}.
     */
    function deploySrc(
        IBaseEscrow.Immutables calldata immutables,
        IOrderMixin.Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    ) external payable onlyOwner {

        IBaseEscrow.Immutables memory immutablesMem = immutables;
        immutablesMem.timelocks = TimelocksLib.setDeployedAt(immutables.timelocks, block.timestamp);
        address computed = _FACTORY.addressOfEscrowSrc(immutablesMem);

        (bool success,) = address(computed).call{value: immutablesMem.safetyDeposit}("");
        if (!success) revert IBaseEscrow.NativeTokenSendingFailure();

        // _ARGS_HAS_TARGET = 1 << 251
        takerTraits = TakerTraits.wrap(TakerTraits.unwrap(takerTraits) | uint256(1 << 251));
        bytes memory argsMem = abi.encodePacked(computed, args);
        _LOP.fillOrderArgs(order, r, vs, amount, takerTraits, argsMem);
    }

    /**
     * @notice See {IResolverExample-deployDst}.
     */
    function deployDst(IBaseEscrow.Immutables calldata dstImmutables, uint256 srcCancellationTimestamp) external onlyOwner payable {
        _FACTORY.createDstEscrow{value: msg.value}(dstImmutables, srcCancellationTimestamp);
    }

    function withdraw(IEscrow escrow, bytes32 secret, IBaseEscrow.Immutables calldata immutables) external {
        escrow.withdraw(secret, immutables);
    }


    function cancel(IEscrow escrow, IBaseEscrow.Immutables calldata immutables) external {
        escrow.cancel(immutables);
    }

    /**
     * @notice See {IResolverExample-arbitraryCalls}.
     */
    function arbitraryCalls(address[] calldata targets, bytes[] calldata arguments) external onlyOwner {
        uint256 length = targets.length;
        if (targets.length != arguments.length) revert LengthMismatch();
        for (uint256 i = 0; i < length; ++i) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = targets[i].call(arguments[i]);
            if (!success) RevertReasonForwarder.reRevert();
        }
    }
}
