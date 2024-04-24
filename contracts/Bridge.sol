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
    error NothingToWithdraw(); // Used when trying to withdraw but there's nothing to withdraw.
    error InsufficientToWithdraw(); // Used when trying to withdraw token but the balance is insufficient to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error InsufficientFee(); // Used when trying to send ccip message but fee is insufficient.
    error InsufficientInTarget(); // Used when trying to send token but target balance is insufficient.
    error InvalidMessageType(); // Used when trying to send token but message type is invalid.

    // Event emitted when a message is sent to another chain.
    event AddLiquidity(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed targetChainSelector, // The chain selector of the target chain.
        address receiver, // The address of the receiver on the target chain.
        uint16 msgType, // The type of message.
        address toAddress, // The address to receive token.
        uint16 tokenId, // The token id.
        uint256 amount, // The amount of token.
        uint256 fee // The fee paid for sending the message.
    );
    event SendToken(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed targetChainSelector, // The chain selector of the target chain.
        address receiver, // The address of the receiver on the target chain.
        uint16 msgType, // The type of message.
        address toAddress, // The address to receive token.
        uint16 tokenId, // The token id.
        uint256 amount, // The amount of token.
        uint256 fee // The fee paid for sending the message.
    );
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        uint16 msgType, // The type of message.
        address toAddress, // The address to receive token.
        uint16 tokenId, // The token id.
        uint256 amount // The amount of token.
    );
    event SetTargetChainSelector(uint64 _targetChainSelector);
    event SetTargetBridge(address _targetBridge);
    event SetProtocolFee(uint256 _protocolFee);
    event AddToken(uint16 _tokenId, address _token);
    event RemoveToken(uint16 _tokenId, address _token);
    event Withdraw(address _beneficiary);
    event WithdrawToken(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed targetChainSelector, // The chain selector of the target chain.
        address receiver, // The address of the receiver on the target chain.
        uint16 msgType, // The type of message.
        address toAddress, // The address to receive token.
        uint16 tokenId, // The token id.
        uint256 amount, // The amount of token.
        address beneficiary, // The address of beneficiary.
        uint256 fee // The fee paid for sending the message.
    );

    uint16 internal constant TYPE_REQUEST_ADD_LIQUIDITY = 1;
    uint16 internal constant TYPE_REQUEST_SEND_TOKEN = 2;
    uint16 internal constant TYPE_REQUEST_WITHDRAW_TOKEN = 3;

    mapping(uint16 => address) public id2token; // tokenId => address
    mapping(address => uint16) public token2id; // address => tokenId
    uint16 public lastTokenId;
    mapping(uint16 => uint256) public targetBalance; // tokenId => amount
    uint64 public targetChainSelector;
    address public targetBridge;
    uint256 public protocolFee;
    IRouterClient public router;

    modifier isSupportedToken(address _token) {
        require(token2id[_token] != 0, "Not supported token");
        _;
    }

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    constructor(address _router) CCIPReceiver(_router) {
        router = IRouterClient(_router);
    }

    receive() external payable {}

    function getSupportedTokens() public view returns (address[] memory) {
        address[] memory tokens = new address[](lastTokenId);
        uint16 i;
        for (uint16 id = 1; id <= lastTokenId; ++id) {
            address token = id2token[id];
            if (token == address(0)) continue;
            tokens[i] = token;
            ++i;
        }
        return tokens;
    }

    function _quoteCcipFee(
        uint16 msgType,
        address toAddress,
        uint16 tokenId,
        uint256 amount
    )
        internal
        view
        returns (Client.EVM2AnyMessage memory evm2AnyMessage, uint256 fee)
    {
        evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(targetBridge),
            data: abi.encode(msgType, toAddress, tokenId, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        fee = router.getFee(targetChainSelector, evm2AnyMessage);
    }

    function quoteAddLiquidityFee(
        address token,
        uint256 amount
    ) public view returns (Client.EVM2AnyMessage memory, uint256) {
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 fee
        ) = _quoteCcipFee(
                TYPE_REQUEST_ADD_LIQUIDITY,
                msg.sender,
                token2id[token],
                amount
            );
        return (evm2AnyMessage, fee);
    }

    function quoteSendFee(
        address token,
        uint256 amount
    ) public view returns (Client.EVM2AnyMessage memory, uint256) {
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 fee
        ) = _quoteCcipFee(
                TYPE_REQUEST_SEND_TOKEN,
                msg.sender,
                token2id[token],
                amount
            );
        fee = fee + protocolFee;
        return (evm2AnyMessage, fee);
    }

    function addLiquidity(
        address token,
        uint256 amount
    ) external payable nonReentrant isSupportedToken(token) {
        // Check received amount
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 amountToBridge = balanceAfter - balanceBefore;
        uint16 tokenId = token2id[token];

        // Quote message and fee
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 ccipFee
        ) = _quoteCcipFee(
                TYPE_REQUEST_ADD_LIQUIDITY,
                msg.sender,
                tokenId,
                amountToBridge
            );
        if (msg.value < ccipFee) revert InsufficientFee();

        // Send the message
        bytes32 messageId = router.ccipSend{value: ccipFee}(
            targetChainSelector,
            evm2AnyMessage
        );

        // Refund excess Eth
        uint _excessEth = msg.value - ccipFee;
        if (_excessEth > 0) {
            payable(msg.sender).transfer(_excessEth);
        }

        // Emit an event with message details
        emit AddLiquidity(
            messageId,
            targetChainSelector,
            targetBridge,
            TYPE_REQUEST_ADD_LIQUIDITY,
            msg.sender,
            tokenId,
            amountToBridge,
            ccipFee
        );
    }

    function send(
        address token,
        uint256 amount
    ) external payable nonReentrant isSupportedToken(token) {
        // Check received amount
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 amountToBridge = balanceAfter - balanceBefore;
        uint16 tokenId = token2id[token];
        
        if (amountToBridge > targetBalance[tokenId]) revert InsufficientInTarget();

        // Quote message and fee
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 ccipFee
        ) = _quoteCcipFee(
                TYPE_REQUEST_SEND_TOKEN,
                msg.sender,
                tokenId,
                amountToBridge
            );
        uint256 fee = ccipFee + protocolFee;
        if (msg.value < fee) revert InsufficientFee();

        // Send the message
        bytes32 messageId = router.ccipSend{value: ccipFee}(
            targetChainSelector,
            evm2AnyMessage
        );

        targetBalance[tokenId] -= amountToBridge;

        // Refund excess Eth
        uint _excessEth = msg.value - fee;
        if (_excessEth > 0) {
            payable(msg.sender).transfer(_excessEth);
        }

        // Emit an event with message details
        emit SendToken(
            messageId,
            targetChainSelector,
            targetBridge,
            TYPE_REQUEST_SEND_TOKEN,
            msg.sender,
            tokenId,
            amountToBridge,
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

        (
            uint16 msgType,
            address toAddress,
            uint16 tokenId,
            uint256 amount
        ) = abi.decode(latestData, (uint16, address, uint16, uint256));

        if (msgType == TYPE_REQUEST_ADD_LIQUIDITY) {
            targetBalance[tokenId] += amount;
        } else if (msgType == TYPE_REQUEST_SEND_TOKEN) {
            address token = id2token[tokenId];
            IERC20(token).safeTransfer(toAddress, amount);
            targetBalance[tokenId] += amount;
        } else if (msgType == TYPE_REQUEST_WITHDRAW_TOKEN) {
            targetBalance[tokenId] -= amount;
        } else {
            revert InvalidMessageType();
        }

        emit MessageReceived(
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            msgType,
            toAddress,
            tokenId,
            amount
        );
    }

    // Owner functions
    function setTargetChainSelector(
        uint64 _targetChainSelector
    ) external onlyOwner {
        require(_targetChainSelector != 0, "ChainSelector can't be 0");
        targetChainSelector = _targetChainSelector;
        emit SetTargetChainSelector(_targetChainSelector);
    }

    function setTargetBridge(address _targetBridge) external onlyOwner {
        require(_targetBridge != address(0), "TargetBridge can't be 0x0");
        targetBridge = _targetBridge;
        emit SetTargetBridge(_targetBridge);
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

    function removeToken(
        address token
    ) external onlyOwner isSupportedToken(token) {
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
    function withdraw(address beneficiary) external onlyOwner {
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
    function withdrawToken(
        address token,
        uint256 amount,
        address beneficiary
    ) external payable onlyOwner isSupportedToken(token) {
        if (amount == 0) revert NothingToWithdraw();
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (amount > balance) revert InsufficientToWithdraw();

        uint16 tokenId = token2id[token];
        // Quote message and fee
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 ccipFee
        ) = _quoteCcipFee(
                TYPE_REQUEST_WITHDRAW_TOKEN,
                msg.sender,
                tokenId,
                amount
            );
        if (msg.value < ccipFee) revert InsufficientFee();

        IERC20(token).safeTransfer(beneficiary, amount);

        // Send the message
        bytes32 messageId = router.ccipSend{value: ccipFee}(
            targetChainSelector,
            evm2AnyMessage
        );

        // Refund excess Eth
        uint _excessEth = msg.value - ccipFee;
        if (_excessEth > 0) {
            payable(msg.sender).transfer(_excessEth);
        }

        emit WithdrawToken(
            messageId,
            targetChainSelector,
            targetBridge,
            TYPE_REQUEST_WITHDRAW_TOKEN,
            msg.sender,
            tokenId,
            amount,
            beneficiary,
            ccipFee
        );
    }
}
