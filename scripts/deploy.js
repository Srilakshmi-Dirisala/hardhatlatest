// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs=require('fs')
async function main() {
  const [deployer]=await hre.ethers.getSigners()

  const balance=await deployer.provider.getBalance(deployer.address);
  console.log(`Account balance: ${balance.toString()}`);

  const Token=await hre.ethers.getContractFactory('Token');
  const token=await Token.deploy();
  console.log(`Token address: ${token.target}`);

  const data = {
    address: token.target,
    abiJsonString: JSON.stringify(token.interface),
    abiString: token.interface
  };
  console.log("abistring",data);
}
  

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
.then(()=>{
  process.exit(0)
})
.catch((error) => {
  console.error(error);
  process.exit(1);
});
