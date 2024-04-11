const hre = require('hardhat');
const { ethers } = require('hardhat');
const {
  getTargetAddress,
} = require('../scripts/helpers');
const { chainSelectors, usdts, tokenAbi } = require('../scripts/constants');

describe('Test in livenet', () => {
  let accounts;
  let ownerAddress;

  describe('Test Bridge', () => {
    it.skip(`Add liquidity`, async () => {
      const [owner] = await ethers.getSigners();
      const network = hre.network.name;
      const BridgeAddress = getTargetAddress('Bridge', network);
      const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
      const tokenAddress = usdts[network];
      const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, owner);
      const amount = ethers.utils.parseUnits('10', 6);
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
  })

  // before(async () => {
  //   accounts = await ethers.getSigners();
  //   ownerAddress = (await ethers.getSigners())[0].address;
  // });
  // after(async () => {});
  // beforeEach(async () => {
  // });
  // afterEach(async () => {
  // });
  // it(`Send`, async () => {
  //   const network = hre.network.name;
  //   const destChain = 'optimisticEthereum';
  //   const destinationChainSelector = chainSelectors[destChain];
  //   const sender = getTargetAddress('BasicMessageSender', network);
  //   const receiver = getTargetAddress('BasicMessageReceiver', destChain);
  //   const messageText = "Hello";
  //   const payFeesIn = 0;  // Native
  //   // const payFeesIn = 1;  // LINK
  //   console.log({destinationChainSelector}, {receiver}, {messageText}, {payFeesIn});
  //   let BasicMessageSender = await ethers.getContractAt('BasicMessageSender', sender);
  //   let tx = await BasicMessageSender.send(destinationChainSelector, receiver, messageText, payFeesIn);
  //   await tx.wait();
  // });
  // it(`Withdraw`, async () => {
  //   const network = hre.network.name;
  //   const sender = getTargetAddress('BasicMessageSender', network);
  //   const beneficiary = ownerAddress;
  //   const BasicMessageSender = await ethers.getContractAt('BasicMessageSender', sender);
  //   let tx = await BasicMessageSender.withdraw(beneficiary);
  //   await tx.wait();
  //   const token = links[network];
  //   tx = await BasicMessageSender.withdrawToken(beneficiary, token);
  //   await tx.wait();
  // });
});
