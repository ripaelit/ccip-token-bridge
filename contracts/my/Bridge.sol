// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract Bridge is CCIPReceiver, OwnerIsCreator, ReentrancyGuard {
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
        uint16 tokenId, // The token id.
        uint256 amount, // The amount of token.
        uint256 fee // The fee paid for sending the message.
    );

    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        uint16 msgType, // The type of message.
        uint16 tokenId, // The token id.
        uint256 amount  // The amount of token.
    );

    event AddToken(uint16 _tokenId, address _token);
    event RemoveToken(uint16 _tokenId, address _token);
    event SetDestinationChainSelector(uint64 _destinationChainSelector);
    event SetDestinationBridge(address _destinationBridge);
    event SetProtocolFee(uint256 _protocolFee);
    event Withdraw(address _beneficiary);
    event WithdrawToken(address _token, address _beneficiary);

    uint16 internal constant TYPE_REQUEST_ADD_LIQUIDITY = 1;
    uint16 internal constant TYPE_REQUEST_SEND_TOKEN = 2;

    mapping(uint16 => address) public id2token;  // tokenId => address
    mapping(address => uint16) public token2id;  // address => tokenId
    uint16 public lastTokenId;
    mapping(uint16 => uint256) destinationBalance;  // tokenId => amount
    uint64 public destinationChainSelector;
    address public destinationBridge;
    uint256 public protocolFee;

    modifier isSupportedToken(address _token) {
        require(token2id[_token] > 0, "Not supported token");
        _;
    }

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router) CCIPReceiver(router) {
    }

    receive() external payable {}

    function getSupportedTokens() public view returns (address[] memory) {
        address[] memory tokens = new address[](lastTokenId);
        uint16 i;
        for (uint16 id = 1; id <= lastTokenId; ++id) {
            address token = id2token[id];
            if (token == address(0))    continue;
            tokens[i] = token;
            ++i;
        }
        return tokens;
    }

    function quoteAddLiquidity() public view returns (uint256 fee) {
        uint16 tokenId;
        uint256 amount;
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_ADD_LIQUIDITY, tokenId, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        IRouterClient router = IRouterClient(this.getRouter());
        fee = router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    function quoteSend() public view returns (uint256 fee) {
        uint16 tokenId;
        uint256 amount;
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_SEND_TOKEN, msg.sender, tokenId, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        IRouterClient router = IRouterClient(this.getRouter());
        uint256 ccipFee = router.getFee(destinationChainSelector, evm2AnyMessage);
        fee = ccipFee + protocolFee;
    }

    function addLiquidity(address token, uint256 amount) external payable nonReentrant isSupportedToken(token) {
        // Check received amount
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 amountIncreased = balanceAfter - balanceBefore;
        uint16 tokenId = token2id[token];

        // Create a message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_ADD_LIQUIDITY, tokenId, amountIncreased),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the message
        uint256 ccipFee = router.getFee(destinationChainSelector, evm2AnyMessage);
        require(msg.value >= ccipFee, "Insufficient fee");

        // Send the message
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
            tokenId,
            amountIncreased,
            ccipFee
        );
    }

    function send(address token, uint256 amount) external payable nonReentrant isSupportedToken(token) {
        // Check received amount
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 amountIncreased = balanceAfter - balanceBefore;
        uint16 tokenId = token2id[token];
        
        // Check destination balance
        require(amountIncreased <= destinationBalance[tokenId], "Insufficient liquidity on destination");

        // Create a message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationBridge),
            data: abi.encode(TYPE_REQUEST_SEND_TOKEN, msg.sender, tokenId, amountIncreased),
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

        // Send the message
        bytes32 messageId = router.ccipSend{value: ccipFee}(
            destinationChainSelector,
            evm2AnyMessage
        );

        // Update destination balance
        destinationBalance[tokenId] -= amountIncreased;

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
            tokenId,
            amountIncreased,
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

        address toAddress;
        uint16 tokenId;
        uint256 amount;

        if (msgType == TYPE_REQUEST_ADD_LIQUIDITY) {
            (,tokenId, amount) = abi.decode(latestData, (uint16, uint16, uint256));
            destinationBalance[tokenId] += amount;
        } else if (msgType == TYPE_REQUEST_SEND_TOKEN) {
            (, toAddress, tokenId, amount) = abi.decode(latestData, (uint16, address, uint16, uint256));
            address token = id2token[tokenId];
            IERC20(token).safeTransfer(toAddress, amount);
            destinationBalance[tokenId] += amount;
        } else {
            revert("Invalid message type");
        }
        
        emit MessageReceived(
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            msgType,
            tokenId,
            amount
        );
    }

    // Owner functions
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

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        require(_protocolFee != 0, "Zero fee");
        protocolFee = _protocolFee;
        emit SetProtocolFee(_protocolFee);
    }

    function addToken(address token) external onlyOwner {
        require(token != address(0), "Token can't be 0x0");
        require(token2id[token] == 0, "Token exists");
        ++lastTokenId;
        token2id[token] = lastTokenId;
        id2token[lastTokenId] = token;
        emit AddToken(lastTokenId, token);
    }

    function removeToken(address token) external onlyOwner isSupportedToken(token) {
        require(token != address(0), "Token can't be 0x0");
        uint16 oldTokenId = token2id[token];
        token2id[token] = 0;
        id2token[oldTokenId] = address(0);
        emit RemoveToken(oldTokenId, token);
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

        emit Withdraw(beneficiary);
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token.
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param token The address of token to withdraw.
    /// @param beneficiary The address to which the tokens will be sent.
    function withdrawToken(address token, address beneficiary) public onlyOwner isSupportedToken(token) {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(token).safeTransfer(beneficiary, amount);

        emit WithdrawToken(token, beneficiary);
    }
}
