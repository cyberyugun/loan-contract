const path = require('path');
const fs = require('fs');
const solc = require('solc');

const contractPath = path.resolve(__dirname, 'loan.sol');
const source = fs.readFileSync(contractPath, 'utf8');
const compiledContract = solc.compile(source, 1);
const bytecode = compiledContract.contracts[':Loan'].bytecode;
const abi = JSON.parse(compiledContract.contracts[':Loan'].interface);

console.log("Bytecode:", bytecode);
console.log("ABI:", abi);