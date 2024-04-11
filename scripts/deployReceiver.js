const { deployReceiver } = require("./helpers.js");

async function main() {
  await deployReceiver();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
