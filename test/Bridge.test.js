const hre = require('hardhat');
const { ethers } = require('hardhat');
const {
  getTargetAddress,
} = require('../scripts/helpers');
const { usdts, tokenAbi } = require('../scripts/constants');

describe('Test Bridge', () => {
  it.skip(`Add liquidity`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const BridgeAddress = getTargetAddress('Bridge', network);
    const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
    const tokenAddress = usdts[network];
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('10000', 6);
    console.log({BridgeAddress}, {tokenAddress}, {amount})
    
    tx = await tokenContract.approve(BridgeAddress, amount);
    await tx.wait();
    console.log(`approved ${amount}`);

    const fee = await Bridge.quoteAddLiquidity();
    console.log(`fee: ${fee.toString()}`);

    tx = await Bridge.addLiquidity(amount, {value: fee});
    await tx.wait();
    console.log(`addLiquidity ${amount}`);
  });
  it.only(`Send token`, async () => {
    const [owner] = await ethers.getSigners();
    const network = hre.network.name;
    const BridgeAddress = getTargetAddress('Bridge', network);
    const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
    const tokenAddress = usdts[network];
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
    const amount = ethers.utils.parseUnits('5', 6);
    
    tx = await tokenContract.approve(BridgeAddress, amount);
    await tx.wait();
    console.log(`approved ${amount}`);

    const fee = await Bridge.quoteSend();
    console.log(`fee: ${fee.toString()}`);

    tx = await Bridge.send(amount, {value: fee});
    await tx.wait();
    console.log(`send ${amount}`);
  });
});
