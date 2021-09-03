const path = require('path')
const Utils = require('../Utils');
const hre = require("hardhat")
const secretsObj = require("../.secrets.js");

module.exports = async ({getUnnamedAccounts, deployments, ethers, network}) => {

    try{

        const {deploy} = deployments;
        const accounts = await getUnnamedAccounts();

        let signers = await hre.ethers.getSigners()

        let account = accounts[0];

        Utils.infoMsg("Deploying Factory Contract")

        //deploy dataStore contract
        let deployedDataStore = await deploy('AgreementToken', {
            from: account,
            log:  false
        });

        let dataStoreAddress = deployedDataStore.address;

        Utils.successMsg(`Factory Contract Address: ${dataStoreAddress}`);


    } catch (e){
        console.log(e,e.stack)
    }

} //end for 

//module.exports.tags = ['ERC20TokenPlus'];

