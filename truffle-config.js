const path = require("path");
require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = process.env.MNEMONIC || "";

// Kovan id - 42
const netConfigRemoteNode = function(net_name, net_id, process, mnemonic) {
  return {
    provider: function() {
      return new HDWalletProvider(mnemonic, `https://${net_name}.infura.io/v3/${process.env.INFURA_API_KEY}`);
    },
    gas: 9000000,
    gasPrice: 32000000000,
    network_id: net_id,
    timeoutBlocks: 200,
    networkCheckTimeout: 100000
  };
};

const netConfigLocalNode = function(net_id) {
  return {
    provider: function() {
      return new HDWalletProvider(mnemonic, `http://127.0.0.1:8545`);
    },
    network_id: net_id,
    gas: 9000000,
    gasPrice: 57000000000,
    timeoutBlocks: 200,
    networkCheckTimeout: 100000
  };
};

module.exports = {
  contracts_build_directory: path.join(__dirname, "./build"),
  networks: {
    development: netConfigLocalNode('*'),
    mainnet_infura: netConfigRemoteNode('mainnet', '1', process, mnemonic),
    mainnet_infura_storage_only: netConfigRemoteNode('mainnet', '1', process, mnemonic),
    mainnet_local_node: netConfigLocalNode('1'),
    kovan_infura: netConfigRemoteNode('kovan', '42', process, mnemonic),
    kovan_local_node: netConfigLocalNode('42')
  },
  etherscan: {
    apiKey: "11G6I8CNXRXI5CW63PTM9YEFZ326WQ41MY"
  },
  mocha: {
    reporter: 'eth-gas-reporter'
  },
  compilers: {
    solc: {
      version: "=0.6.6",
      settings: {
        optimizer: {
          enabled: true
        }
      }
    }
  }
};
