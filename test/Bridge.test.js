const hre = require("hardhat");
const { ethers } = require("hardhat");
const {
  getTargetAddress,
  deployBridge,
  deployMockUSDT,
  deployMockUSDC,
} = require("../scripts/helpers");
const {
  tokens,
  tokenAbi,
  targetChains,
  chainSelectors,
} = require("../scripts/constants");

describe("Test Bridge", () => {
  let owner;
  let network;
  let BridgeAddress;
  let Bridge;
  beforeEach("setup", async () => {
    [owner] = await ethers.getSigners();
    network = hre.network.name;
    BridgeAddress = getTargetAddress(`Bridge`, network);
    Bridge = await ethers.getContractAt("Bridge", BridgeAddress);
  });
  it(`Deploy`, async () => {
    if (network == "hardhat" || network == "localhost") {
      await deployBridge();
      await deployMockUSDT();
      await deployMockUSDC();
    } else {
      console.log("Already deployed");
    }
  });
  // it(`Mint`, async () => {
  //   const tokenAddress = tokens[network].musdt;
  //   const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
  //   const amount = ethers.utils.parseUnits('10000', 6);
  //   console.log(`token balance before: ${await tokenContract.balanceOf(owner.address)}`);
  //   tx = await tokenContract.mint(owner.address, amount);
  //   await tx.wait();
  //   console.log(`token balance After: ${await tokenContract.balanceOf(owner.address)}`);
  // });
  it(`Register MUSDT`, async () => {
    const localToken = tokens[network].musdt;
    const remoteChain = targetChains[network][0];
    const remoteChainSelector = chainSelectors[remoteChain];
    const remoteToken = tokens[remoteChain].musdt;
    tx = await Bridge.registerToken(
      localToken,
      remoteChainSelector,
      remoteToken
    );
    await tx.wait();
  });
  it(`Verify MUSDT`, async () => {
    const localToken = tokens[network].musdt;
    const remoteChain = targetChains[network][0];
    const remoteChainSelector = chainSelectors[remoteChain];
    const remoteToken = tokens[remoteChain].musdt;
    tx = await Bridge.verifyToken(
      localToken,
      remoteChainSelector,
      remoteToken,
      true
    );
    await tx.wait();
  });
  it(`Add liquidity MUSDT`, async () => {
    const localToken = tokens[network].musdt;
    const remoteChain = targetChains[network][0];
    const remoteChainSelector = chainSelectors[remoteChain];
    const remoteToken = tokens[remoteChain].musdt;
    const tokenContract = new ethers.Contract(localToken, tokenAbi, owner);
    const amount = ethers.utils.parseUnits("1000", 6);

    const allowance = await tokenContract.allowance(
      owner.address,
      BridgeAddress
    );
    if (allowance.lt(amount)) {
      tx = await tokenContract.approve(BridgeAddress, amount);
      await tx.wait();
      console.log(`approved ${amount.toString()}`);
    }

    console.log(
      `token balance before: ${await tokenContract.balanceOf(owner.address)}`
    );
    tx = await Bridge.addLiquidity(
      localToken,
      amount,
      remoteChainSelector,
      remoteToken
    );
    await tx.wait();
    console.log(
      `addLiquidity(${localToken}, ${amount}, ${remoteChainSelector}, ${remoteToken}) in ${network}`
    );
    console.log(
      `token balance after: ${await tokenContract.balanceOf(owner.address)}`
    );
  });
  it.only(`Send MUSDT`, async () => {
    const localToken = tokens[network].musdt;
    const remoteChain = targetChains[network][0];
    const remoteBridge = getTargetAddress("Bridge", remoteChain);
    const remoteChainSelector = chainSelectors[remoteChain];
    const remoteToken = tokens[remoteChain].musdt;
    const tokenContract = new ethers.Contract(localToken, tokenAbi, owner);
    const amount = ethers.utils.parseUnits("200", 6);

    const allowance = await tokenContract.allowance(
      owner.address,
      BridgeAddress
    );
    if (allowance.lt(amount)) {
      tx = await tokenContract.approve(BridgeAddress, amount);
      await tx.wait();
      console.log(`approved ${amount.toString()}`);
    }

    const [_, fee] = await Bridge.quoteSendFee(
      localToken,
      amount,
      remoteBridge,
      remoteChainSelector,
      remoteToken
    );
    console.log(`fee: ${fee.toString()}`);

    console.log(
      `token balance before: ${await tokenContract.balanceOf(owner.address)}`
    );
    tx = await Bridge.send(
      localToken,
      amount,
      remoteBridge,
      remoteChainSelector,
      remoteToken,
      { value: fee }
    );
    await tx.wait();
    console.log(
      `send(${localToken}, ${amount}, ${remoteBridge}, ${remoteChainSelector}, ${remoteToken}, {${fee}}) in bridge in ${network}`
    );
    console.log(
      `token balance after: ${await tokenContract.balanceOf(owner.address)}`
    );
  });
});
