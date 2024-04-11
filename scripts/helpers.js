const fs = require('fs');
const deployments = require('./deployments.json');
const gasReport = require('./gasReport.json');
const hre = require('hardhat');
const { ethers, run } = require('hardhat');
const { routers, links, usdts, dstChains, chainSelectors } = require("./constants");

const getTargetAddress = (contractName, network) => {
  return deployments[network][contractName];
};

const setTargetAddress = (contractName, network, address) => {
  if (!process.env.ADDRESS_REPORT) return;

  if (deployments[network] == undefined) {
    deployments[network] = {};
  }
  deployments[network][contractName] = address;
  fs.writeFileSync('scripts/deployments.json', JSON.stringify(deployments), function (err) {
    if (err) return console.log(err);
  });
  console.log(`${contractName} | ${network} | ${address}`);
};

const setGasReport = async (contractName, network, balanceBefore) => {
  if (!process.env.GAS_REPORT) return;

  let accounts = await ethers.getSigners();
  let owner = accounts[0];
  let balanceAfter = await ethers.provider.getBalance(owner.address);
  let gasPrice = await ethers.provider.getGasPrice();
  let gasUsed = balanceBefore.sub(balanceAfter).div(gasPrice).toNumber();

  if (gasReport[network] == undefined) {
    gasReport[network] = {};
  }
  gasReport[network][contractName] = gasUsed;

  fs.writeFileSync('scripts/gasReport.json', JSON.stringify(gasReport), function (err) {
    if (err) return console.log(err);
  });
  console.log(`${contractName} | ${network} | gasPrice ${gasPrice} | gasUsed ${gasUsed}`);

  return balanceAfter;
};

// const verifyTherundownConsumerTest = async () => {
//   // hre.changeNetwork(network);
//   let network = hre.network.name;
//   const chainlink = require(`./constants/chainlink/${network}.json`);
//   console.log('LINK address: ', chainlink['LINK']);
//   console.log('ORACLE address: ', chainlink['ORACLE']);

//   try {
//     await run('verify:verify', {
//       address: getTargetAddress('TherundownConsumerTest', network),
//       constructorArguments: [chainlink['LINK'], chainlink['ORACLE']],
//     });
//     console.log('Verified TherundownConsumerTest');
//   } catch (e) {
//     console.log(e);
//   }
// };

const deploySender = async () => {
  // hre.changeNetwork(network);
  let network = hre.network.name;
  let accounts = await ethers.getSigners();
  let owner = accounts[0];
  let balanceBefore = await ethers.provider.getBalance(owner.address);
  console.log(`network: ${network}, owner: ${owner.address}, balance: ${balanceBefore}`)

  const router = routers[network];
  const link = links[network];
  const BasicMessageSenderFactory = await ethers.getContractFactory("BasicMessageSender");
  const BasicMessageSender = await BasicMessageSenderFactory.deploy(router, link);
  await BasicMessageSender.deployed();
  setTargetAddress("BasicMessageSender", network, BasicMessageSender.address);
  await setGasReport("BasicMessageSender", network, balanceBefore);

  try {
    await run('verify:verify', {
      address: getTargetAddress('BasicMessageSender', network),
      constructorArguments: [router, link],
    });
    console.log('Verified BasicMessageSender');
  } catch (e) {
    console.log(e);
  }
};

const deployReceiver = async () => {
  // hre.changeNetwork(network);
  let network = hre.network.name;
  let accounts = await ethers.getSigners();
  let owner = accounts[0];
  let balanceBefore = await ethers.provider.getBalance(owner.address);
  console.log(`network: ${network}, owner: ${owner.address}, balance: ${balanceBefore}`)

  const router = routers[network];
  const BasicMessageReceiverFactory = await ethers.getContractFactory("BasicMessageReceiver");
  const BasicMessageReceiver = await BasicMessageReceiverFactory.deploy(router);
  await BasicMessageReceiver.deployed();
  setTargetAddress("BasicMessageReceiver", network, BasicMessageReceiver.address);
  await setGasReport("BasicMessageReceiver", network, balanceBefore);

  try {
    await run('verify:verify', {
      address: getTargetAddress('BasicMessageReceiver', network),
      constructorArguments: [router],
    });
    console.log('Verified BasicMessageReceiver');
  } catch (e) {
    console.log(e);
  }
};

const deployBridge = async () => {
  // hre.changeNetwork(network);
  let network = hre.network.name;
  let accounts = await ethers.getSigners();
  let owner = accounts[0];
  let balanceBefore = await ethers.provider.getBalance(owner.address);
  console.log(`network: ${network}, owner: ${owner.address}, balance: ${balanceBefore}`)

  const router = routers[network];
  const BridgeFactory = await ethers.getContractFactory("Bridge");
  const Bridge = await BridgeFactory.deploy(router);
  await Bridge.deployed();
  setTargetAddress("Bridge", network, Bridge.address);
  await setGasReport("Bridge", network, balanceBefore);

  try {
    await run('verify:verify', {
      address: getTargetAddress('Bridge', network),
      constructorArguments: [router],
    });
    console.log('Verified Bridge');
  } catch (e) {
    console.log(e);
  }
};

const configBridge = async () => {
  const network = hre.network.name;
  const BridgeAddress = getTargetAddress('Bridge', network);
  const Bridge = await ethers.getContractAt('Bridge', BridgeAddress);
  const token = usdts[network];
  const dstChain = dstChains[network];
  const dstChainSelector = chainSelectors[dstChain]
  const dstBridge = getTargetAddress('Bridge', dstChain);
  console.log({token}, {dstChain}, {dstChainSelector}, {dstBridge});

  tx = await Bridge.setToken(token);
  await tx.wait();

  tx = await Bridge.setDestinationChainSelector(dstChainSelector);
  await tx.wait();

  tx = await Bridge.setDestinationBridge(dstBridge);
  await tx.wait();
}

const deployMockUSDT = async () => {
  // hre.changeNetwork(network);
  let network = hre.network.name;
  let accounts = await ethers.getSigners();
  let owner = accounts[0];
  let balanceBefore = await ethers.provider.getBalance(owner.address);
  console.log(`network: ${network}, owner: ${owner.address}, balance: ${balanceBefore}`)

  const MockUSDTFactory = await ethers.getContractFactory("MockUSDT");
  const MockUSDT = await MockUSDTFactory.deploy("Mock USDT", "MUSDT");
  await MockUSDT.deployed();
  setTargetAddress("MockUSDT", network, MockUSDT.address);
  await setGasReport("MockUSDT", network, balanceBefore);

  try {
    await run('verify:verify', {
      address: getTargetAddress('MockUSDT', network),
      constructorArguments: ["Mock USDT", "MUSDT"],
    });
    console.log('Verified MockUSDT');
  } catch (e) {
    console.log(e);
  }
};

module.exports = {
  getTargetAddress,
  setTargetAddress,
  setGasReport,
  deploySender,
  deployReceiver,
  deployBridge,
  configBridge,
  deployMockUSDT
};
