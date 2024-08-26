import {
  BaseContract,
  ContractTransactionReceipt,
  EventFragment,
} from 'ethers';
import { ethers } from 'hardhat';
import { Libraries } from 'hardhat/types';

export const deploy = async <Type>(
  typeName: string,
  libraries?: Libraries,
  ...args: any[]
): Promise<Type> => {
  const ctrFactory = await ethers.getContractFactory(typeName, { libraries });

  const ctr = (await ctrFactory.deploy(...args)) as unknown as Type;
  await (ctr as unknown as BaseContract).waitForDeployment();
  return ctr;
};

export const getContractAt = async <Type>(
  typeName: string,
  address: string,
): Promise<Type> => {
  const ctr = (await ethers.getContractAt(
    typeName,
    address,
  )) as unknown as Type;
  return ctr;
};

export const awaitQuestChainAddress = async (
  receipt: ContractTransactionReceipt | null,
) => {
  if (!receipt || !receipt.logs) return '';
  const abi = new ethers.Interface([
    'event QuestChainCreated(uint256 id, address questChain)',
  ]);
  const eventFragment = EventFragment.from(abi.fragments[0]);
  const eventTopic = eventFragment.topicHash;
  const event = receipt.logs.find(e => e.topics[0] === eventTopic);
  if (event) {
    const decodedLog = abi.decodeEventLog(
      eventFragment,
      event.data,
      event.topics,
    );
    return decodedLog.questChain;
  }
  return '';
};

export enum Status {
  init,
  review,
  pass,
  fail,
}

export const numberToBytes32 = (num: number) => {
  const beArray = ethers.toBeArray(num);
  const hexlified = ethers.hexlify(beArray);
  return ethers.zeroPadValue(hexlified, 32);
};
