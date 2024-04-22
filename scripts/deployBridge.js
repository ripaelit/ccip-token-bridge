const { targetChains } = require("./constants/index.js");
const { deployBridge } = require("./helpers.js");
const hre = require('hardhat');

async function main() {
  const network = hre.network.name;
  for (const targetChain of targetChains[network]) {
    await deployBridge(targetChain);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
