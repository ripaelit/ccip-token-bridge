const { deployMockUSDT } = require("./helpers.js");

async function main() {
  await deployMockUSDT();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
