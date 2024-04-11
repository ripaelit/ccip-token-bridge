const { configBridge } = require("./helpers.js");

async function main() {
  await configBridge();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
