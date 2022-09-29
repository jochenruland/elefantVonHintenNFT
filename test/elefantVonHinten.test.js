const assert = require('assert');
const path = require('path');
const fs = require('fs');
const {expect} = require('chai');

const { Buffer } = require('buffer');

/**
  * @dev current version of ipfs-http-client is ESM only
  * @dev const ipfsClient = require('ipfs-http-client'); // only works with version 33.1.1
  * const client = new ipfsClient({
  *    host: 'ipfs.infura.io',
  *    port: 5001,
  *    protocol: 'https',
  *    headers: {
  *        authorization: auth,
  *    },
  * });
  */

const apiKeys = require('../API_KEYS.json');
const projectId = apiKeys.projectId;
const projectSecret = apiKeys.projectSecret;
const auth =
    'Basic ' + Buffer.from(projectId + ':' + projectSecret).toString('base64');

async function loadIPFSclient() {
  const { create } = await import('ipfs-http-client')

  const node = await create({
    host: 'ipfs.infura.io',
    port: 5001,
    protocol: 'https',
    headers: {
        authorization: auth
      }
  })

  return node;
}

const options = {
    reconnect: {
        auto: true,
        delay: 5000, // ms
        maxAttempts: 5,
        onTimeout: false
    }
};

const Web3 = require('web3');
const provider = new Web3.providers.WebsocketProvider('http://127.0.0.1:7545', options);
const web3 = new Web3(provider);

const ElefantVonHintenJSON = require('../build/contracts/ElefantVonHinten.json');
const deploymentKey = Object.keys(ElefantVonHintenJSON.networks)[0];

let accounts;
let contractInstance;
let sendParamaters;


let dataURL;
let metadataURL;
let client;

before(async () => {
  accounts = await web3.eth.getAccounts();
  contractInstance = new web3.eth.Contract(ElefantVonHintenJSON.abi, ElefantVonHintenJSON.networks[deploymentKey].address);

  // Web3 transaction information, we'll use this for every transaction we'll send as long as we do not pass any value
  sendParamaters = {
    from: accounts[0],
    gasLimit: web3.utils.toHex(5000000),
    gasPrice: web3.utils.toHex(20000000000)
  };

  client = await loadIPFSclient();

})

describe('Testing ElefantVonHintenNFT on mainnetForkfork', () => {

  it('1. Contract deployed to mainfork and address available', () => {
    console.log('Mainfork connected: ', accounts);
    console.log('1. Contract address: ', contractInstance.options.address);
    assert.ok(contractInstance.options.address);
  });

  it('2. Connects to ipfs-http-client', () => {
      console.log(client.getEndpointConfig()); //
  });

  it('3. Sets all state variables', async () => {
    //console.log(await contractInstance.methods.maxTokens().call({from: accounts[0]}));
    expect(await contractInstance.methods.maxTokens().call({from: accounts[0]})).to.equal('5');
  });

});
