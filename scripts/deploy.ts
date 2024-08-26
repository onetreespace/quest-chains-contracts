import { execSync } from 'child_process';
import fs from 'fs';
import { ethers, network, run } from 'hardhat';

import { QuestChain, QuestChainFactory } from '../types';
import {
  DEFAULT_UPGRADE_FEE,
  NETWORK_CURRENCY,
  NETWORK_NAME,
  PAYMENT_TOKEN,
  TREASURY_ADDRESS,
  validateSetup,
} from './utils';
import { ContractTransactionResponse } from 'ethers';

async function main() {
  const { chainId, address, balance } = await validateSetup();
  if (!ethers.provider) {
    throw new Error('Provider not found for network');
  }
  const commitHash = execSync('git rev-parse --short HEAD', {
    encoding: 'utf-8',
  }).trim();

  console.log('Deploying QuestChainFactory:', NETWORK_NAME[chainId]);
  console.log('Commit Hash:', commitHash);

  const QuestChain = await ethers.getContractFactory('QuestChain', {});
  const questChain = (await QuestChain.deploy()) as QuestChain;
  await questChain.waitForDeployment()
  console.log('Template Address:', await questChain.getAddress());

  const QuestChainFactory = await ethers.getContractFactory(
    'QuestChainFactory',
  );
  const questChainFactory = (await QuestChainFactory.deploy(
    await questChain.getAddress(),
    address,
  )) as QuestChainFactory & { deploymentTransaction(): ContractTransactionResponse }
  await questChainFactory.waitForDeployment();
  console.log('Factory Address:', await questChainFactory.getAddress());

  const questChainTokenAddress = await questChainFactory.questChainToken();
  console.log('Token Address:', questChainTokenAddress);

  const txHash = questChainFactory.deploymentTransaction()?.hash;
  if (!txHash) {
    throw new Error('Transaction hash not found');
  }
  console.log('Transaction Hash:', txHash);
  const receipt = await ethers.provider.getTransactionReceipt(txHash);

  if (!receipt) {
    throw new Error('Transaction receipt not found');
  }
  console.log('Block Number:', receipt.blockNumber);

  const afterBalance = await ethers.provider.getBalance(address);
  const gasUsed = balance - (afterBalance);
  console.log(
    'Gas Used:',
    ethers.formatEther(gasUsed),
    NETWORK_CURRENCY[chainId],
  );
  console.log(
    'Account Balance:',
    ethers.formatEther(afterBalance),
    NETWORK_CURRENCY[chainId],
  );

  if (chainId === 31337) {
    return;
  }

  const deploymentInfo = {
    network: network.name,
    version: commitHash,
    factory: await questChainFactory.getAddress(),
    token: questChainTokenAddress,
    template: await questChain.getAddress(),
    txHash,
    blockNumber: receipt.blockNumber.toString(),
  };

  fs.writeFileSync(
    `deployments/${network.name}.json`,
    JSON.stringify(deploymentInfo, undefined, 2),
  );

  try {
    console.log('Waiting for contracts to be indexed...');
    await questChainFactory.deploymentTransaction()?.wait(10);
    console.log('Verifying Contracts...');

    await run('verify', {
      address: await questChain.getAddress(),
      constructorArguments: [],
    });
    console.log('Verified Template');

    await run('verify', {
      address: await questChainFactory.getAddress(),
      constructorArguments: [
        await questChain.getAddress(),
        address,
        TREASURY_ADDRESS[chainId],
        PAYMENT_TOKEN[chainId],
        DEFAULT_UPGRADE_FEE,
      ],
    });
    console.log('Verified Factory');

    await run('verify', {
      address: questChainTokenAddress,
      constructorArguments: [],
    });
    console.log('Verified Token');
  } catch (err) {
    console.error('Error verifying contracts:', err);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
