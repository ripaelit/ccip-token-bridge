const hre = require('hardhat');
const { ethers } = require('hardhat');
const {
  getTargetAddress,
} = require('../scripts/helpers');
const { tokens, tokenAbi } = require('../scripts/constants');

describe('Test Bridge', () => {
  it.skip(`Add liquidity MUSDT`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const BridgeAddress = getTargetAddress('Bridge', network);
    const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
    const tokenAddress = tokens[network].musdt;
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('10000', 6);
    
    tx = await tokenContract.approve(BridgeAddress, amount);
    await tx.wait();
    console.log(`approved ${amount.toString()}`);

    const fee = await Bridge.quoteAddLiquidity();
    console.log(`fee: ${fee.toString()}`);

    console.log(`token balance before: ${await tokenContract.balanceOf(owner.address)}`);

    tx = await Bridge.addLiquidity(tokenAddress, amount, {value: fee});
    await tx.wait();
    console.log(`addLiquidity()`);

    console.log(`token balance after: ${await tokenContract.balanceOf(owner.address)}`);
  });
  it.only(`Send MUSDT`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const BridgeAddress = getTargetAddress('Bridge', network);
    const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
    const tokenAddress = tokens[network].musdt;
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('500', 6);
    
    tx = await tokenContract.approve(BridgeAddress, amount);
    await tx.wait();
    console.log(`approved ${amount.toString()}`);

    const fee = await Bridge.quoteSend();
    console.log(`fee: ${fee.toString()}`);

    console.log(`token balance before: ${await tokenContract.balanceOf(owner.address)}`);

    tx = await Bridge.send(tokenAddress, amount, {value: fee});
    await tx.wait();
    console.log(`send()`);

    console.log(`token balance after: ${await tokenContract.balanceOf(owner.address)}`);
  });
});
