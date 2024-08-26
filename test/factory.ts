import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

import {
  QuestChain,
  QuestChainFactory,
  QuestChainToken,
  QuestChainToken__factory,
} from '../types';
import { QuestChainCommons } from '../types/contracts/QuestChainFactory';
import {
  awaitQuestChainAddress,
  deploy,
  getContractAt,
  numberToBytes32,
} from './utils/helpers';

const DETAILS_STRING = 'ipfs://details';
const URI_STRING = 'ipfs://uri';

describe('QuestChainFactory', () => {
  let questChainTemplate: QuestChain;
  let chainFactory: QuestChainFactory;
  let signers: HardhatEthersSigner[];
  let chainAddress: string;
  let DEFAULT_ADMIN_ROLE: string;
  let ADMIN_ROLE: string;
  let EDITOR_ROLE: string;
  let REVIEWER_ROLE: string;
  let admin: string;
  let questChainToken: QuestChainToken;

  before(async () => {
    signers = await ethers.getSigners();
    admin = signers[0].address;

    questChainTemplate = await deploy<QuestChain>('QuestChain', {});

    [DEFAULT_ADMIN_ROLE, ADMIN_ROLE, EDITOR_ROLE, REVIEWER_ROLE] =
      await Promise.all([
        questChainTemplate.DEFAULT_ADMIN_ROLE(),
        questChainTemplate.ADMIN_ROLE(),
        questChainTemplate.EDITOR_ROLE(),
        questChainTemplate.REVIEWER_ROLE(),
      ]);

    chainFactory = await deploy<QuestChainFactory>(
      'QuestChainFactory',
      {},
      await questChainTemplate.getAddress(),
      admin,
    );

    await expect(chainFactory.deploymentTransaction()).to.emit(
      chainFactory,
      'FactorySetup',
    );

    questChainToken = QuestChainToken__factory.connect(
      await chainFactory.questChainToken(),
      signers[0],
    );

    expect(DEFAULT_ADMIN_ROLE).to.equal(numberToBytes32(0));
  });

  it('Should be initialized properly', async () => {
    expect(await chainFactory.questChainCount()).to.equal(0);
    expect(await chainFactory.admin()).to.equal(admin);
    expect(await chainFactory.questChainTemplate()).to.equal(
      await questChainTemplate.getAddress(),
    );
  });

  it('Should revert init for questChainTemplate', async () => {
    const info: QuestChainCommons.QuestChainInfoStruct = {
      details: DETAILS_STRING,
      tokenURI: URI_STRING,
      owners: [admin],
      admins: [],
      editors: [],
      reviewers: [],
      quests: [],
      paused: false,
    };
    const tx = questChainTemplate.init(info);
    await expect(tx).to.revertedWithCustomError(
      questChainTemplate,
      'InvalidInitialization',
    );
  });

  describe('create', async () => {
    it('Should deploy a QuestChain', async () => {
      const info: QuestChainCommons.QuestChainInfoStruct = {
        details: DETAILS_STRING,
        tokenURI: URI_STRING,
        owners: [admin],
        admins: [],
        editors: [],
        reviewers: [],
        quests: [],
        paused: false,
      };
      const tx = await chainFactory.create(info, numberToBytes32(0));
      chainAddress = await awaitQuestChainAddress(await tx.wait());
      await expect(tx)
        .to.emit(chainFactory, 'QuestChainCreated')
        .withArgs(0, chainAddress);

      const chain = await getContractAt<QuestChain>('QuestChain', chainAddress);
      await expect(tx)
        .to.emit(chain, 'QuestChainInit')
        .withArgs(DETAILS_STRING, [], false);

      expect(await chain.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true);
      expect(await chain.hasRole(ADMIN_ROLE, admin)).to.equal(true);
      expect(await chain.hasRole(EDITOR_ROLE, admin)).to.equal(true);
      expect(await chain.hasRole(REVIEWER_ROLE, admin)).to.equal(true);

      expect(await chain.getRoleAdmin(DEFAULT_ADMIN_ROLE)).to.equal(
        DEFAULT_ADMIN_ROLE,
      );
      expect(await chain.getRoleAdmin(ADMIN_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
      expect(await chain.getRoleAdmin(EDITOR_ROLE)).to.equal(ADMIN_ROLE);
      expect(await chain.getRoleAdmin(REVIEWER_ROLE)).to.equal(ADMIN_ROLE);

      expect(await chainFactory.getQuestChainAddress(0)).to.equal(chainAddress);
    });

    it('Should deploy a QuestChain with roles', async () => {
      const owners = [admin, signers[5].address];
      const admins = [signers[1].address, signers[2].address];
      const editors = [signers[2].address, signers[3].address];
      const reviewers = [signers[3].address, signers[4].address];
      const info: QuestChainCommons.QuestChainInfoStruct = {
        details: DETAILS_STRING,
        tokenURI: URI_STRING,
        owners,
        admins,
        editors,
        reviewers,
        quests: [],
        paused: false,
      };
      const tx = await chainFactory.create(info, numberToBytes32(1));
      chainAddress = await awaitQuestChainAddress(await tx.wait());
      await expect(tx)
        .to.emit(chainFactory, 'QuestChainCreated')
        .withArgs(1, chainAddress);

      const chain = await getContractAt<QuestChain>('QuestChain', chainAddress);
      await expect(tx)
        .to.emit(chain, 'QuestChainInit')
        .withArgs(DETAILS_STRING, [], false);

      await Promise.all(
        owners.map(async owner =>
          expect(await chain.hasRole(DEFAULT_ADMIN_ROLE, owner)).to.equal(true),
        ),
      );
      await Promise.all(
        owners.map(async owner =>
          expect(await chain.hasRole(ADMIN_ROLE, owner)).to.equal(true),
        ),
      );
      await Promise.all(
        admins.map(async admin =>
          expect(await chain.hasRole(ADMIN_ROLE, admin)).to.equal(true),
        ),
      );
      await Promise.all(
        owners.map(async owner =>
          expect(await chain.hasRole(EDITOR_ROLE, owner)).to.equal(true),
        ),
      );
      await Promise.all(
        admins.map(async admin =>
          expect(await chain.hasRole(EDITOR_ROLE, admin)).to.equal(true),
        ),
      );
      await Promise.all(
        editors.map(async editor =>
          expect(await chain.hasRole(EDITOR_ROLE, editor)).to.equal(true),
        ),
      );
      await Promise.all(
        owners.map(async owner =>
          expect(await chain.hasRole(REVIEWER_ROLE, owner)).to.equal(true),
        ),
      );
      await Promise.all(
        admins.map(async admin =>
          expect(await chain.hasRole(REVIEWER_ROLE, admin)).to.equal(true),
        ),
      );
      await Promise.all(
        editors.map(async editor =>
          expect(await chain.hasRole(REVIEWER_ROLE, editor)).to.equal(true),
        ),
      );
      await Promise.all(
        reviewers.map(async reviewer =>
          expect(await chain.hasRole(REVIEWER_ROLE, reviewer)).to.equal(true),
        ),
      );

      expect(await chainFactory.getQuestChainAddress(1)).to.equal(chainAddress);
    });

    it('Should update questChainCount', async () => {
      expect(await chainFactory.questChainCount()).to.equal(2);
      const info: QuestChainCommons.QuestChainInfoStruct = {
        details: DETAILS_STRING,
        tokenURI: URI_STRING,
        owners: [admin],
        admins: [],
        editors: [],
        reviewers: [],
        quests: [],
        paused: false,
      };

      let tx = await chainFactory.create(info, numberToBytes32(2));
      const chain0 = await awaitQuestChainAddress(await tx.wait());
      expect(await chainFactory.questChainCount()).to.equal(3);
      tx = await chainFactory.create(info, numberToBytes32(3));
      const chain1 = await awaitQuestChainAddress(await tx.wait());
      expect(await chainFactory.questChainCount()).to.equal(4);

      expect(await chainFactory.getQuestChainAddress(2)).to.equal(chain0);
      expect(await chainFactory.getQuestChainAddress(3)).to.equal(chain1);
    });

    it('Should create quests & paused', async () => {
      expect(await chainFactory.questChainCount()).to.equal(4);
      const info: QuestChainCommons.QuestChainInfoStruct = {
        details: DETAILS_STRING,
        tokenURI: URI_STRING,
        owners: [admin],
        admins: [],
        editors: [],
        reviewers: [],
        quests: ['1', '2', '3'],
        paused: true,
      };

      const tx = await chainFactory.create(info, numberToBytes32(4));

      const chainAddress = await awaitQuestChainAddress(await tx.wait());

      expect(await chainFactory.questChainCount()).to.equal(5);

      const chain = await getContractAt<QuestChain>('QuestChain', chainAddress);

      await expect(tx)
        .to.emit(chain, 'QuestChainInit')
        .withArgs(DETAILS_STRING, ['1', '2', '3'], true);

      expect(await chain.paused()).to.equal(true);
      expect(await chain.questCount()).to.equal(3);
    });

    it('Should revert create quest chain with no owners', async () => {
      expect(await chainFactory.questChainCount()).to.equal(5);
      const info: QuestChainCommons.QuestChainInfoStruct = {
        details: DETAILS_STRING,
        tokenURI: URI_STRING,
        owners: [],
        admins: [],
        editors: [],
        reviewers: [],
        quests: ['1', '2', '3', '4'],
        paused: true,
      };

      const txPromise = chainFactory.create(info, numberToBytes32(5));

      await expect(txPromise).to.be.revertedWithCustomError(
        questChainTemplate,
        'NoOwners',
      );
    });
  });

  describe('questChainToken', async () => {
    it('Should revert set token owner', async () => {
      const txPromise = questChainToken.setTokenOwner(0, signers[0].address);
      await expect(txPromise).to.be.revertedWithCustomError(
        questChainToken,
        'NotFactory',
      );
    });
    it('Should revert set token uri', async () => {
      const txPromise = questChainToken.setTokenURI(0, URI_STRING);
      await expect(txPromise).to.be.revertedWithCustomError(
        questChainToken,
        'NotTokenOwner',
      );
    });
  });

  describe('replacing admin', async () => {
    it('Should revert admin change proposal when sender is not admin', async () => {
      const tx = chainFactory
        .connect(signers[1])
        .proposeAdminReplace(signers[1].address);
      await expect(tx).to.be.revertedWithCustomError(chainFactory, 'NotAdmin');
    });

    it('Should revert admin change proposal when new admin is 0 address', async () => {
      const tx = chainFactory.proposeAdminReplace(ethers.ZeroAddress);
      await expect(tx).to.be.revertedWithCustomError(
        chainFactory,
        'ZeroAddress',
      );
    });

    it('Should be able to create a proposal for replacing admin', async () => {
      const tx = await chainFactory.proposeAdminReplace(signers[1].address);
      await expect(tx)
        .to.emit(chainFactory, 'AdminReplaceProposed')
        .withArgs(signers[1].address);
      expect(await chainFactory.proposedAdmin()).to.equal(signers[1].address);
    });

    it('Should revert admin change proposal when new admin is same as old proposed admin', async () => {
      const tx = chainFactory.proposeAdminReplace(signers[1].address);
      await expect(tx).to.be.revertedWithCustomError(
        chainFactory,
        'NoAddressChange',
      );
    });

    it('Should revert admin change execution if one day has not passed', async () => {
      const tx = chainFactory.connect(signers[1]).executeAdminReplace();
      await expect(tx).to.be.revertedWithCustomError(chainFactory, 'TooSoon');
    });

    it('Should revert admin change execution if not proposed admin', async () => {
      await ethers.provider.send('evm_setNextBlockTimestamp', [
        Number((await chainFactory.adminProposalTimestamp()) + 864000n),
      ]);
      const tx = chainFactory.executeAdminReplace();
      await expect(tx).to.be.revertedWithCustomError(
        chainFactory,
        'NotProposedAdmin',
      );
    });

    it('Should execute admin change after one day', async () => {
      const tx = await chainFactory.connect(signers[1]).executeAdminReplace();
      await expect(tx)
        .to.emit(chainFactory, 'AdminReplaced')
        .withArgs(signers[1].address);
      expect(await chainFactory.admin()).to.equal(signers[1].address);
    });
  });
});
