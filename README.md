# @quest-chains/contracts

Solidity smart contracts of the Quest Chains protocol.

```shell
yarn compile
yarn test
yarn coverage
```

#### Roles

- REVIEWER role is the most basic with ability to review quests
- EDITOR has REVIEWER role and extra ability to add/remove/edit quests
- ADMIN has EDITOR role and ability to add/remove EDITORs/REVIEWERs
- OWNER has ADMIN role + ability to add/remove ADMINs/OWNERs
