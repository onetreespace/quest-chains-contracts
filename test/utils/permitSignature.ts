import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { ethers } from 'hardhat';

import { MockERC20Token } from '../../types';

export const getPermitSignature = async (
  wallet: HardhatEthersSigner,
  token: MockERC20Token,
  spender: string,
  value: bigint = ethers.MaxUint256,
  deadline = ethers.MaxUint256,
): Promise<string> => {
  const network = await ethers.provider.getNetwork();
  const [nonce, name, version, chainId] = await Promise.all([
    token.nonces(wallet.address),
    token.name(),
    '1',
    network.chainId,
  ]);

  return wallet.signTypedData(
    {
      name,
      version,
      chainId,
      verifyingContract: await token.getAddress(),
    },
    {
      Permit: [
        {
          name: 'owner',
          type: 'address',
        },
        {
          name: 'spender',
          type: 'address',
        },
        {
          name: 'value',
          type: 'uint256',
        },
        {
          name: 'nonce',
          type: 'uint256',
        },
        {
          name: 'deadline',
          type: 'uint256',
        },
      ],
    },
    {
      owner: wallet.address,
      spender,
      value,
      nonce,
      deadline,
    },
  );
};
