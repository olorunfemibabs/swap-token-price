const { DefenderRelayProvider, DefenderRelaySigner } = require('defender-relay-client/lib/ethers');
const { ethers } = require('hardhat');
const { writeFileSync, readFileSync, appendFileSync } = require('fs');
const { AdminClient } = require('defender-admin-client');
const { RelayClient } = require('defender-relay-client');
const contractABI = JSON.stringify(JSON.parse(readFileSync('artifacts/@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json', 'utf8')).abi);


async function main() {
    require('dotenv').config();
    const adminClient = new AdminClient({
        apiKey: process.env.TEAM_API_KEY,
        apiSecret: process.env.TEAM_SECRET_KEY,
    });

    const { RELAYER_API_KEY: apiKey, RELAYER_API_SECRET: apiSecret } = process.env;

    const credentials = { apiKey, apiSecret }

    const provider = new DefenderRelayProvider(credentials);
    const relaySigner = new DefenderRelaySigner(credentials, provider, {
        speed: 'fast',
    });

    const Forwarder = await ethers.getContractFactory('SwapToken');
    const forwarder = await Forwarder.connect(relaySigner).deploy();
    await forwarder.deployed();

    const contract = {
        network: 'goerli',
        address: forwarder.address,
        name: 'SwapToken',
        abi: contractABI,
    }

    const newAdminClient = await adminClient.addContract(contract);
    console.log(forwarder.address);

    writeFileSync('deploy.json', JSON.stringify({Auction: forwarder.address}, null,2,));

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});