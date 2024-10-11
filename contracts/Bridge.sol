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
import {EarningContract} from "./EarningContract.sol";

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
    error UnregisteredToken(); // Used when trying to send unregistered token.
    error UnverifiedToken(); // Used when trying to send unverified token.

    // Event emitted when a message is sent to another chain.
    event AddLiquidity(
        uint64 indexed remoteChainSelector, // The chain selector of the target chain.
        address localToken, // The local token which will be added.
        address remoteToken, // The remote token for the local token.
        uint256 amount // The amount of token.
    );
    event SendToken(
        bytes32 indexed messageId, // The unique ID of the message.
        address localToken, // The local token which will be sent.
        uint256 amount, // The amount of token.
        address remoteBridge, // The remote bridge address.
        uint64 remoteChainSelector, // The chain selector of the target chain.
        address remoteToken, // The remote token which will be received.
        bytes32 tokenId, // The token id.
        uint256 fee // The fee paid for sending the message.
    );
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        uint16 msgType, // The type of message.
        address toAddress, // The address to receive token.
        bytes32 tokenId, // The token id.
        uint256 amount // The amount of token.
    );
    event SetProtocolFee(uint256 _protocolFee);
    event SetClientRegisterTokenFee(uint256 _clientRegisterTokenFee);
    event SetEarningContract(address _earningContract);
    event SetAdmin(address _admin);
    event SetBonusToken(address _bonusToken);
    event SetBonusAirdropAmount(uint256 _bonusAirdropAmount);
    event SetBonusEnable(bool _bonusEnable);
    event RegisterToken(
        address _localToken,
        uint64 _remoteChainSelector,
        address _remoteToken,
        bytes32 _tokenId
    );
    event DeregisterToken(bytes32 _tokenId, address _token);
    event WithdrawFee();
    event WithdrawToken(
        address token, // The token address to withdraw.
        uint256 amount // The amount of token.
    );
    event DepositBonusToken(uint256 amount);
    event WithdrawBonusToken(uint256 amount);

    uint16 internal constant TYPE_REQUEST_SEND_TOKEN = 1;

    IRouterClient public router;
    uint256 public protocolFee;
    uint256 public clientRegisterTokenFee;
    address public earningContract;
    address public admin;
    address public bonusToken;
    uint256 public bonusAirdropAmount;
    bool public bonusEnable;
    uint256 public totalBonusAmountSent;
    uint256 public bonusTokenBalance;
    uint64 public chainSelector;
    mapping(bytes32 => address) public id2token; // tokenId => token address
    mapping(bytes32 => bool) public verified; // tokenId => verified

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    constructor(address _router, uint64 _chainSelector) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        chainSelector = _chainSelector;
    }

    receive() external payable {}

    function getBonusTokenInfo()
        public
        view
        returns (address, uint256, uint256, bool, uint256)
    {
        return (
            bonusToken,
            bonusTokenBalance,
            bonusAirdropAmount,
            bonusEnable,
            totalBonusAmountSent
        );
    }

    function getTokenId(
        address localToken,
        uint64 remoteChainSelector,
        address remoteToken
    ) public view returns (bytes32 tokenId) {
        if (localToken < remoteToken) {
            tokenId = keccak256(
                abi.encodePacked(
                    chainSelector,
                    localToken,
                    remoteChainSelector,
                    remoteToken
                )
            );
        } else {
            tokenId = keccak256(
                abi.encodePacked(
                    remoteChainSelector,
                    remoteToken
                    chainSelector,
                    localToken,
                )
            );
        }
    }

    function _quoteCcipFee(
        uint16 msgType,
        address remoteBridge,
        uint64 remoteChainSelector,
        address toAddress,
        bytes32 tokenId,
        uint256 amount
    )
        internal
        view
        returns (Client.EVM2AnyMessage memory evm2AnyMessage, uint256 fee)
    {
        evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(remoteBridge),
            data: abi.encode(msgType, toAddress, tokenId, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        fee = router.getFee(remoteChainSelector, evm2AnyMessage);
    }

    function quoteSendFee(
        address localToken,
        uint256 amount,
        address remoteBridge,
        uint64 remoteChainSelector,
        address remoteToken
    ) public view returns (Client.EVM2AnyMessage memory, uint256) {
        // Check token validation
        bytes32 tokenId = getTokenId(localToken, remoteChainSelector, remoteToken);
        if (id2token[tokenId] != localToken) revert UnregisteredToken();
        if (!verified[tokenId]) revert UnverifiedToken();

        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 ccipFee
        ) = _quoteCcipFee(
                TYPE_REQUEST_SEND_TOKEN,
                remoteBridge,
                remoteChainSelector,
                msg.sender,
                tokenId,
                amount
            );
        return (evm2AnyMessage, ccipFee + protocolFee);
    }

    function addLiquidity(
        uint64 remoteChainSelector,
        address localToken,
        address remoteToken,
        uint256 amount
    ) external nonReentrant {
        // Check token validation
        bytes32 tokenId = getTokenId(localToken, remoteChainSelector, remoteToken);
        if (id2token[tokenId] != localToken) revert UnregisteredToken();
        if (!verified[tokenId]) revert UnverifiedToken();

        IERC20(localToken).safeTransferFrom(msg.sender, address(this), amount);

        // Emit an event with message details
        emit AddLiquidity(remoteChainSelector, localToken, remoteToken, amount);
    }

    function send(
        address localToken,
        uint256 amount,
        address remoteBridge,
        uint64 remoteChainSelector,
        address remoteToken
    ) external payable nonReentrant {
        // Check token validation
        bytes32 tokenId = getTokenId(localToken, remoteChainSelector, remoteToken);
        if (id2token[tokenId] != localToken) revert UnregisteredToken();
        if (!verified[tokenId]) revert UnverifiedToken();

        // Check received amount
        uint256 balanceBefore = IERC20(localToken).balanceOf(address(this));
        IERC20(localToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(localToken).balanceOf(address(this));
        uint256 amountToBridge = balanceAfter - balanceBefore;

        // Quote message and fee
        (
            Client.EVM2AnyMessage memory evm2AnyMessage,
            uint256 ccipFee
        ) = _quoteCcipFee(
                TYPE_REQUEST_SEND_TOKEN,
                remoteBridge,
                remoteChainSelector,
                msg.sender,
                tokenId,
                amountToBridge
            );
        uint256 fee = ccipFee + protocolFee;
        if (msg.value < fee) revert InsufficientFee();

        // Send the message
        bytes32 messageId = router.ccipSend{value: ccipFee}(
            remoteChainSelector,
            evm2AnyMessage
        );

        // Refund excess Eth
        uint _excessEth = msg.value - fee;
        if (_excessEth > 0) {
            payable(msg.sender).transfer(_excessEth);
        }

        // Pay bonus token
        if (
            localToken != bonusToken &&
            bonusEnable &&
            bonusTokenBalance > bonusAirdropAmount
        ) {
            IERC20(bonusToken).safeTransfer(msg.sender, bonusAirdropAmount);
            bonusTokenBalance -= bonusAirdropAmount;
            totalBonusAmountSent += bonusAirdropAmount;
        }

        // Emit an event with message details
        emit SendToken(
            messageId,
            localToken,
            amountToBridge,
            remoteBridge,
            remoteChainSelector,
            remoteToken,
            tokenId,
            fee
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
            bytes32 tokenId,
            uint256 amount
        ) = abi.decode(latestData, (uint16, address, bytes32, uint256));

        if (msgType == TYPE_REQUEST_SEND_TOKEN) {
            address token = id2token[tokenId];
            if (token != address(0)) {
                IERC20(token).safeTransfer(toAddress, amount);
            } else {
                revert UnregisteredToken();
            }
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

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        require(_protocolFee != 0, "Zero fee");
        protocolFee = _protocolFee;
        emit SetProtocolFee(_protocolFee);
    }

    function setClientRegisterTokenFee(
        uint256 _clientRegisterTokenFee
    ) external onlyOwner {
        require(_clientRegisterTokenFee != 0, "Zero fee");
        clientRegisterTokenFee = _clientRegisterTokenFee;
        emit SetClientRegisterTokenFee(_clientRegisterTokenFee);
    }

    function setEarningContract(address _earningContract) external onlyOwner {
        require(_earningContract != address(0), "EarningContract can't be 0x0");
        earningContract = _earningContract;
        emit SetEarningContract(_earningContract);
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin can't be 0x0");
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function setBonusToken(address _bonusToken) external onlyOwner {
        require(_bonusToken != address(0), "BonusToken can't be 0x0");
        bonusToken = _bonusToken;
        emit SetBonusToken(_bonusToken);
    }

    function setBonusAirdropAmount(
        uint256 _bonusAirdropAmount
    ) external onlyOwner {
        require(_bonusAirdropAmount != 0, "Zero amount");
        bonusAirdropAmount = _bonusAirdropAmount;
        emit SetBonusAirdropAmount(_bonusAirdropAmount);
    }

    function setBonusEnable(bool _bonusEnable) external onlyOwner {
        bonusEnable = _bonusEnable;
        emit SetBonusEnable(_bonusEnable);
    }

    function registerToken(
        address localToken,
        uint64 remoteChainSelector,
        address remoteToken
    ) external payable nonReentrant {
        if (msg.sender != owner()) {
            require(
                msg.value >= clientRegisterTokenFee,
                "Insufficient register fee"
            );
        }

        // Check token validation
        bytes32 tokenId = getTokenId(localToken, remoteChainSelector, remoteToken);
        require(id2token[tokenId] == address(0), "Already registered");

        id2token[tokenId] = localToken;

        // Refund excess Eth
        if (msg.sender != owner()) {
            uint _excessEth = msg.value - clientRegisterTokenFee;
            if (_excessEth > 0) {
                payable(msg.sender).transfer(_excessEth);
            }
        }

        emit RegisterToken(
            localToken,
            remoteChainSelector,
            remoteToken,
            tokenId
        );
    }

    function deregisterToken(bytes32 tokenId) external onlyOwner {
        address tokenAddress = id2token[tokenId];
        require(tokenAddress != address(0), "Token ID does not exist");

        delete id2token[tokenId];
        
        emit DeregisterToken(tokenId, tokenAddress);
    }

    function withdrawFee() external nonReentrant onlyOwner {
        uint256 amount = address(this).balance;
        uint256 amountToEarningContract = amount / 2;

        EarningContract(payable(earningContract)).deposit{
            value: amountToEarningContract
        }();

        uint256 amountToAdmin = amount - amountToEarningContract;
        (bool sent, ) = admin.call{value: amountToAdmin}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, admin, amountToAdmin);

        emit WithdrawFee();
    }

    function withdrawToken(
        address token,
        uint256 amount
    ) external onlyOwner {
        if (amount > IERC20(token).balanceOf(address(this)))
            revert InsufficientToWithdraw();

        IERC20(token).safeTransfer(owner(), amount);

        emit WithdrawToken(token, amount);
    }

    function depositBonusToken(uint256 amount) external onlyOwner {
        require(
            amount <= IERC20(bonusToken).balanceOf(msg.sender),
            "Excessive amount"
        );
        IERC20(bonusToken).safeTransferFrom(msg.sender, address(this), amount);
        bonusTokenBalance += amount;
        emit DepositBonusToken(amount);
    }

    function withdrawBonusToken(uint256 amount) external onlyOwner {
        require(amount <= bonusTokenBalance, "Insufficient amount");
        IERC20(bonusToken).safeTransfer(admin, amount);
        bonusTokenBalance -= amount;
        emit WithdrawBonusToken(amount);
    }
}
