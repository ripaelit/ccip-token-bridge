const hre = require('hardhat');
const { ethers } = require('hardhat');
const {
  getTargetAddress,
} = require('../scripts/helpers');
const { tokens, tokenAbi, targetChains } = require('../scripts/constants');

describe('Test Bridge', () => {
  it.skip(`Mint`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const tokenAddress = tokens[network].musdt;
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('10000', 6);
    console.log(`token balance before: ${await tokenContract.balanceOf(owner.address)}`);
    tx = await tokenContract.mint(owner.address, amount);
    await tx.wait();
    console.log(`token balance After: ${await tokenContract.balanceOf(owner.address)}`);
  });
  it.skip(`Add liquidity MUSDT`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const targetChain = targetChains[network][0];
    const BridgeAddress = getTargetAddress(`Bridge-${targetChain}`, network);
    const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
    const tokenAddress = tokens[network].musdt;
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('1000', 6);
    
    const allowance = await tokenContract.allowance(owner.address, BridgeAddress);
    if (allowance.lt(amount)) {
      tx = await tokenContract.approve(BridgeAddress, amount);
      await tx.wait();
      console.log(`approved ${amount.toString()}`);
    }

    const [_, fee] = await Bridge.quoteAddLiquidityFee(tokenAddress, amount);
    console.log(`fee: ${fee.toString()}`);

    console.log(`token balance before: ${await tokenContract.balanceOf(owner.address)}`);
    tx = await Bridge.addLiquidity(tokenAddress, amount, {value: fee});
    await tx.wait();
    console.log(`addLiquidity(${tokenAddress}, ${amount}, {${fee}}) in bridge-${targetChain} in ${network}`);
    console.log(`token balance after: ${await tokenContract.balanceOf(owner.address)}`);
  });
  it.only(`Send MUSDT`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const targetChain = targetChains[network][0];
    const BridgeAddress = getTargetAddress(`Bridge-${targetChain}`, network);
    const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
    const tokenAddress = tokens[network].musdt;
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('200', 6);
    
    const allowance = await tokenContract.allowance(owner.address, BridgeAddress);
    if (allowance.lt(amount)) {
      tx = await tokenContract.approve(BridgeAddress, amount);
      await tx.wait();
      console.log(`approved ${amount.toString()}`);
    }

    const [_, fee] = await Bridge.quoteSendFee(tokenAddress, amount);
    console.log(`fee: ${fee.toString()}`);

    console.log(`token balance before: ${await tokenContract.balanceOf(owner.address)}`);
    tx = await Bridge.send(tokenAddress, amount, {value: fee});
    await tx.wait();
    console.log(`send(${tokenAddress}, ${amount}, {${fee}}) in bridge-${targetChain} in ${network}`);
    console.log(`token balance after: ${await tokenContract.balanceOf(owner.address)}`);
  });
});
