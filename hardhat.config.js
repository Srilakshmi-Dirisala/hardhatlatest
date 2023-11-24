require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
const INFURA_URL='https://goerli.infura.io/v3/797c36988b6c4e14993ea637860bf5f3'
const PRIVATE_KEY='354a56c74d1c990d65f213a504bd5c5edbe6a51439182d18c264c056bf3a5878'

module.exports = {
  solidity: "0.8.19",
  networks:{
    goerli:{
      url:INFURA_URL,
      accounts:[`0x${PRIVATE_KEY}`]
    }
  }
};
