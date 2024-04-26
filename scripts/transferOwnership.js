const { targetChains } = require("./constants/index.js");
const { transferOwnershipBridge } = require("./helpers.js");
const hre = require('hardhat');

async function main() {
  const network = hre.network.name;
  const toAddress = '0xad362783a729E67030201C4064Ff8E2e872E4df9';
  for (const targetChain of targetChains[network]) {
    await transferOwnershipBridge(targetChain, toAddress);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
