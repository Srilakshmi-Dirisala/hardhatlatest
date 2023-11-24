require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
};
require("@nomiclabs/hardhat-waffle");

const endpointUrl = "ADD_YOUR_QUICKNODE_URL_HERE";
const privateKey = "ADD_YOUR_PRIVATE_KEY_HERE";

module.exports = {
  solidity: "0.8.21",
  networks: {
    sepolia: {
      url: endpointUrl,
      accounts: [privateKey],
    },
  },
};