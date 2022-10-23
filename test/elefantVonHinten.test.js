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

describe('Testing ElefantVonHintenNFT on mainnetForkfork - Initialisations', () => {

  it('1. Contract deployed to mainfork and address available', () => {
    console.log('Mainfork connected: ', accounts);

    expect(contractInstance.options.address).to.exist;
    console.log('1. Contract address: ', contractInstance.options.address);
  });

  it('2. IPFS endpoint available', () => {
    expect(client.getEndpointConfig()).to.exist
    console.log(client.getEndpointConfig());
  });

  it('2. Sets all state variables', async () => {
    expect(await contractInstance.methods.name().call({from: accounts[0]})).to.equal('ElefantVonHinten');
    console.log(await contractInstance.methods.name().call({from: accounts[0]}));

    expect(await contractInstance.methods.symbol().call({from: accounts[0]})).to.equal('EVH');
    console.log(await contractInstance.methods.symbol().call({from: accounts[0]}));

    // set maxTokens
    await contractInstance.methods.setMaxTokens(5).send(sendParamaters);
    expect(await contractInstance.methods.maxTokens().call({from: accounts[0]})).to.equal('5');
    console.log(await contractInstance.methods.maxTokens().call({from: accounts[0]}));

    // set maxMints
    await contractInstance.methods.setMaxMints(2).send(sendParamaters);
    expect(await contractInstance.methods.maxMints().call({from: accounts[0]})).to.equal('2');
    console.log(await contractInstance.methods.maxMints().call({from: accounts[0]}));

    // set tokenPrice
    await contractInstance.methods.setTokenPrice(1000).send(sendParamaters);
    expect(await contractInstance.methods.tokenPrice().call({from: accounts[0]})).to.equal('1000');
    console.log(await contractInstance.methods.tokenPrice().call({from: accounts[0]}));

  });
});

  /**
   * @dev sample code for uploading multiple files to ipfs
   */
  /*
  it('X. Upload collection to ipfs', () => {

      //joining path of directory
      const directoryPath = path.join(__dirname, '../data/ElefantVonHinten/');
      //passsing directoryPath and callback function
      fs.readdir(directoryPath, function (err, files) {
        //handling error
        if (err) {
          return console.log('Unable to scan directory: ' + err);
        }
        //listing all files using forEach
        files.forEach(function (file) {
          // Do whatever you want to do with the file - f.ex. upload to IPFS and mint token
          console.log(file);
        });
      });

  });
  */
describe('Testing ElefantVonHintenNFT - Upload data to ipfs and mint tokens', () => {

    let runs = [
      { desc: '1 token minted', args: [1], result: true },
      { desc: '2 token minted', args: [2], result: true },
      { desc: '3 token minted', args: [3], result: false }
    ];

    // an example, not a general case
    runs.forEach(function (run) {
      let verb = run.result ? 'Test should pass' : 'Test should fail';

      it(verb + ' when ' + run.desc, async () => {

        // 1. Get # of token to be minted
        //     -> Check if # of token will execeed maxTokens
        //     -> Check if # of token <= maxMints
        // 2. for each # of token
        //     -> grap file
        //     -> Try adding image to ipfs
        //     -> if upload successful
        //        -> mint token
        const maxTokens = await contractInstance.methods.maxTokens().call({from: accounts[0]});
        let totalSupply = await contractInstance.methods.totalSupply().call({from: accounts[0]});
        const maxMints = await contractInstance.methods.maxMints().call({from: accounts[0]});

        if (totalSupply + run.args > maxTokens || run.args > maxMints) {
          expect(false);
          return;
        }

        for (let i = 0; i < run.args; i++) {

          try {

            const filePath = path.resolve(__dirname, '../data/ElefantVonHinten/', `${totalSupply}.png`);
            console.log("Opening an existing file: ", filePath);

            const file = fs.readFileSync(filePath);

            const addImage = await client.add(
              file,
              {
                progress: (prog) => console.log(`received: ${prog}`)
              }
            );
            console.log('Image has been added: ', addImage);

            dataURL = `https://ipfs.infura.io/ipfs/${addImage.path}`;
            console.log(`URL of ${filePath} -> `, dataURL);

            totalSupply ++;

          } catch (error) {
            console.log(`Error: addImage.path value: ${addImage.path}`);
            console.log(`Error: uploading file: ${filePath}`, error);
          }
        }

        let ethValue = run.args * 1000;

        await contractInstance.methods.mintElefants(run.args).send({
          from: accounts[0],
          gasLimit: web3.utils.toHex(5000000),
          gasPrice: web3.utils.toHex(20000000000),
          value: ethValue.toString()
        });

        console.log(await contractInstance.methods.balanceOf(accounts[0]).call({from: accounts[0]}));

        //expect(result).toEqual(run.result);

      });
    });

  });
