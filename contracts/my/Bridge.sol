// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract Bridge is CCIPReceiver, OwnerIsCreator {
    using SafeERC20 for IERC20;

    // Custom errors to provide more descriptive revert messages.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        uint16 msgType,    // The type of message.
        address receiver, // The address of the receiver on the destination chain.
        uint256 amount, // The amount of token.
        uint256 fee // The fee paid for sending the message.
    );

    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        uint16 msgType    // The type of message.
    );

    event SetToken(address _token);
    event SetDestinationChainSelector(uint64 _destinationChainSelector);
    event SetDestinationBridge(address _destinationBridge);
    event SetFeePercentage(uint256 _feePercentage);
    event SetProtocolFee(uint256 _protocolFee);

    uint16 internal constant TYPE_REQUEST_ADD_LIQUIDITY = 1;
    uint16 internal constant TYPE_REQUEST_SEND_TOKEN = 2;

    address public token;
    uint256 public destinationBalance;
    uint64 public destinationChainSelector;
    address public destinationBridge;
    uint256 public feePercentage;
    uint256 public protocolFee;

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router) CCIPReceiver(router) {
    }

    receive() external payable {}

    function quoteAddLiquidity() public view returns (uint256 fee) {
        uint256 amount;
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_ADD_LIQUIDITY, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        IRouterClient router = IRouterClient(this.getRouter());
        fee = router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    function quoteSend() public view returns (uint256 fee) {
        uint256 amount;
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_SEND_TOKEN, msg.sender, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        IRouterClient router = IRouterClient(this.getRouter());
        uint256 ccipFee = router.getFee(destinationChainSelector, evm2AnyMessage);
        fee = ccipFee + protocolFee;
    }

    function addLiquidity(uint256 amount) external payable {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_ADD_LIQUIDITY, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the message
        uint256 ccipFee = router.getFee(destinationChainSelector, evm2AnyMessage);
        require(msg.value >= ccipFee, "Insufficient fee");

        bytes32 messageId = router.ccipSend{value: ccipFee}(
            destinationChainSelector,
            evm2AnyMessage
        );

        // Refund excess Eth
        uint _excessEth = msg.value - ccipFee;
        if (_excessEth > 0) {
            payable(msg.sender).transfer(_excessEth);
        }

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            TYPE_REQUEST_ADD_LIQUIDITY,
            destinationBridge,
            amount,
            ccipFee
        );
    }

    function send(uint256 amount) external payable {
        require(amount <= destinationBalance, "Insufficient liquidity on destination");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_SEND_TOKEN, msg.sender, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the message
        uint256 ccipFee = router.getFee(destinationChainSelector, evm2AnyMessage);
        uint256 fee = ccipFee + protocolFee;
        require(msg.value >= fee, "Insufficient fee");

        bytes32 messageId = router.ccipSend{value: ccipFee}(
            destinationChainSelector,
            evm2AnyMessage
        );

        destinationBalance = destinationBalance - amount;

        // Refund excess Eth
        uint _excessEth = msg.value - fee;
        if (_excessEth > 0) {
            payable(msg.sender).transfer(_excessEth);
        }

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            TYPE_REQUEST_SEND_TOKEN,
            destinationBridge,
            amount,
            ccipFee
        );
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        bytes32 latestMessageId = any2EvmMessage.messageId;
        uint64 latestSourceChainSelector = any2EvmMessage.sourceChainSelector;
        address latestSender = abi.decode(any2EvmMessage.sender, (address));
        bytes memory latestData = any2EvmMessage.data;

        uint16 msgType;
        assembly {
            msgType := mload(add(latestData, 32))
        }

        if (msgType == TYPE_REQUEST_ADD_LIQUIDITY) {
            (, uint256 amount) = abi.decode(latestData, (uint16, uint256));
            destinationBalance = destinationBalance + amount;
        } else if (msgType == TYPE_REQUEST_SEND_TOKEN) {
            (, address toAddress, uint256 amount) = abi.decode(latestData, (uint16, address, uint256));
            IERC20(token).safeTransfer(toAddress, amount);
            destinationBalance = destinationBalance + amount;
        } else {
            revert("Invalid message type");
        }

        emit MessageReceived(
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            msgType
        );
    }

    // Setters
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Token can't be 0x0");
        token = _token;
        emit SetToken(_token);
    }

    function setDestinationChainSelector(uint64 _destinationChainSelector) external onlyOwner {
        require(_destinationChainSelector != 0, "ChainSelector can't be 0");
        destinationChainSelector = _destinationChainSelector;
        emit SetDestinationChainSelector(_destinationChainSelector);
    }

    function setDestinationBridge(address _destinationBridge) external onlyOwner {
        require(_destinationBridge != address(0), "DestinationBridge can't be 0x0");
        destinationBridge = _destinationBridge;
        emit SetDestinationBridge(_destinationBridge);
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage != 0, "Zero fee");
        feePercentage = _feePercentage;
        emit SetFeePercentage(_feePercentage);
    }

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        require(_protocolFee != 0, "Zero fee");
        protocolFee = _protocolFee;
        emit SetProtocolFee(_protocolFee);
    }

    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract.
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails.
    /// It should only be callable by the owner of the contract.
    /// @param beneficiary The address to which the Ether should be sent.
    function withdraw(address beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token.
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param beneficiary The address to which the tokens will be sent.
    function withdrawToken(
        address beneficiary
    ) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(token).safeTransfer(beneficiary, amount);
    }
}
