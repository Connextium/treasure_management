//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ILocManagement
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iLocManagementAbi = [
  {
    type: 'function',
    inputs: [{ name: 'locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'locContracts',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
] as const

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Loc
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const locAbi = [
  {
    type: 'constructor',
    inputs: [
      { name: '_locNo', internalType: 'uint256', type: 'uint256' },
      { name: '_buyerAcc', internalType: 'address', type: 'address' },
      { name: '_sellerAcc', internalType: 'address', type: 'address' },
      { name: '_amount', internalType: 'uint256', type: 'uint256' },
      { name: '_dateOfIssue', internalType: 'uint256', type: 'uint256' },
      { name: '_dateOfExpiry', internalType: 'uint256', type: 'uint256' },
      {
        name: '_treasureLedgerAddress',
        internalType: 'address',
        type: 'address',
      },
      { name: '_issuingBankAddr', internalType: 'address', type: 'address' },
      { name: '_locManagementAddr', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'activateLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'canFundLC',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'expireLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getAllowance',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getFundingStatus',
    outputs: [
      { name: 'allowance', internalType: 'uint256', type: 'uint256' },
      { name: 'required', internalType: 'uint256', type: 'uint256' },
      { name: 'isFunded', internalType: 'bool', type: 'bool' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getIssuingBankBalance',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getLocData',
    outputs: [
      {
        name: '',
        internalType: 'struct Loc.LocData',
        type: 'tuple',
        components: [
          { name: 'locNo', internalType: 'uint256', type: 'uint256' },
          { name: 'buyerAcc', internalType: 'address', type: 'address' },
          { name: 'sellerAcc', internalType: 'address', type: 'address' },
          { name: 'amount', internalType: 'uint256', type: 'uint256' },
          { name: 'status', internalType: 'bytes2', type: 'bytes2' },
          { name: 'dateOfIssue', internalType: 'uint256', type: 'uint256' },
          { name: 'dateOfExpiry', internalType: 'uint256', type: 'uint256' },
          {
            name: 'treasureLedgerAddress',
            internalType: 'address',
            type: 'address',
          },
          { name: 'createdAt', internalType: 'uint256', type: 'uint256' },
          { name: 'settledAt', internalType: 'uint256', type: 'uint256' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getStatus',
    outputs: [{ name: '', internalType: 'bytes2', type: 'bytes2' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getStatusString',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'isExpired',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'issuingBank',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'locData',
    outputs: [
      { name: 'locNo', internalType: 'uint256', type: 'uint256' },
      { name: 'buyerAcc', internalType: 'address', type: 'address' },
      { name: 'sellerAcc', internalType: 'address', type: 'address' },
      { name: 'amount', internalType: 'uint256', type: 'uint256' },
      { name: 'status', internalType: 'bytes2', type: 'bytes2' },
      { name: 'dateOfIssue', internalType: 'uint256', type: 'uint256' },
      { name: 'dateOfExpiry', internalType: 'uint256', type: 'uint256' },
      {
        name: 'treasureLedgerAddress',
        internalType: 'address',
        type: 'address',
      },
      { name: 'createdAt', internalType: 'uint256', type: 'uint256' },
      { name: 'settledAt', internalType: 'uint256', type: 'uint256' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'locManagement',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'renounceOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'settleLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'newOwner', internalType: 'address', type: 'address' }],
    name: 'transferOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'treasureLedger',
    outputs: [{ name: '', internalType: 'contract IERC20', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'recipient',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'amount',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
      {
        name: 'timestamp',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'FundsReleased',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'timestamp',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'LocActivated',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'timestamp',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'LocExpired',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'beneficiary',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'amount',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
      {
        name: 'timestamp',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'LocSettled',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'newOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'OwnershipTransferred',
  },
  {
    type: 'error',
    inputs: [{ name: 'owner', internalType: 'address', type: 'address' }],
    name: 'OwnableInvalidOwner',
  },
  {
    type: 'error',
    inputs: [{ name: 'account', internalType: 'address', type: 'address' }],
    name: 'OwnableUnauthorizedAccount',
  },
] as const

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LocManagement
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const locManagementAbi = [
  {
    type: 'constructor',
    inputs: [
      {
        name: '_treasureLedgerAddress',
        internalType: 'address',
        type: 'address',
      },
      { name: '_issuingBankAddr', internalType: 'address', type: 'address' },
      { name: '_forwarderAddress', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'activateLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'expireLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getExpectedAuthor',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getExpectedWorkflowId',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getExpectedWorkflowName',
    outputs: [{ name: '', internalType: 'bytes10', type: 'bytes10' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getForwarderAddress',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: '_locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'getLocContractAddress',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: '_locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'getLocData',
    outputs: [
      {
        name: '',
        internalType: 'struct Loc.LocData',
        type: 'tuple',
        components: [
          { name: 'locNo', internalType: 'uint256', type: 'uint256' },
          { name: 'buyerAcc', internalType: 'address', type: 'address' },
          { name: 'sellerAcc', internalType: 'address', type: 'address' },
          { name: 'amount', internalType: 'uint256', type: 'uint256' },
          { name: 'status', internalType: 'bytes2', type: 'bytes2' },
          { name: 'dateOfIssue', internalType: 'uint256', type: 'uint256' },
          { name: 'dateOfExpiry', internalType: 'uint256', type: 'uint256' },
          {
            name: 'treasureLedgerAddress',
            internalType: 'address',
            type: 'address',
          },
          { name: 'createdAt', internalType: 'uint256', type: 'uint256' },
          { name: 'settledAt', internalType: 'uint256', type: 'uint256' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: '_locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'getLocStatus',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: '_locNo', internalType: 'uint256', type: 'uint256' },
      { name: '_buyerAcc', internalType: 'address', type: 'address' },
      { name: '_sellerAcc', internalType: 'address', type: 'address' },
      { name: '_amount', internalType: 'uint256', type: 'uint256' },
      { name: '_dateOfIssue', internalType: 'uint256', type: 'uint256' },
      { name: '_dateOfExpiry', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'issueLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'issuingBank',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    name: 'locContracts',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'metadata', internalType: 'bytes', type: 'bytes' },
      { name: 'report', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'onReport',
    outputs: [],
    stateMutability: 'payable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'renounceOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_author', internalType: 'address', type: 'address' }],
    name: 'setExpectedAuthor',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_id', internalType: 'bytes32', type: 'bytes32' }],
    name: 'setExpectedWorkflowId',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_name', internalType: 'string', type: 'string' }],
    name: 'setExpectedWorkflowName',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_forwarder', internalType: 'address', type: 'address' }],
    name: 'setForwarderAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: '_newIssuingBank', internalType: 'address', type: 'address' },
    ],
    name: 'setIssuingBank',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: '_locNo', internalType: 'uint256', type: 'uint256' }],
    name: 'settleLC',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'interfaceId', internalType: 'bytes4', type: 'bytes4' }],
    name: 'supportsInterface',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'pure',
  },
  {
    type: 'function',
    inputs: [{ name: 'newOwner', internalType: 'address', type: 'address' }],
    name: 'transferOwnership',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'treasureLedger',
    outputs: [
      { name: '', internalType: 'contract ITreasureLedger', type: 'address' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousAuthor',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'newAuthor',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'ExpectedAuthorUpdated',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousId',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'newId',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'ExpectedWorkflowIdUpdated',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousName',
        internalType: 'bytes10',
        type: 'bytes10',
        indexed: true,
      },
      {
        name: 'newName',
        internalType: 'bytes10',
        type: 'bytes10',
        indexed: true,
      },
    ],
    name: 'ExpectedWorkflowNameUpdated',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousForwarder',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'newForwarder',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'ForwarderAddressUpdated',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
    ],
    name: 'LCActivated',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
    ],
    name: 'LCExpired',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'issuingBank',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'amount',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'LCFundsMinted',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'buyerAcc',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'sellerAcc',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'amount',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
      {
        name: 'locContractAddress',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'LCIssued',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'locNo',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
    ],
    name: 'LCSettled',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'previousOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'newOwner',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'OwnershipTransferred',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'message',
        internalType: 'string',
        type: 'string',
        indexed: false,
      },
    ],
    name: 'SecurityWarning',
  },
  { type: 'error', inputs: [], name: 'InvalidAddress' },
  { type: 'error', inputs: [], name: 'InvalidAmount' },
  {
    type: 'error',
    inputs: [
      { name: 'received', internalType: 'address', type: 'address' },
      { name: 'expected', internalType: 'address', type: 'address' },
    ],
    name: 'InvalidAuthor',
  },
  { type: 'error', inputs: [], name: 'InvalidDateRange' },
  { type: 'error', inputs: [], name: 'InvalidForwarderAddress' },
  { type: 'error', inputs: [], name: 'InvalidSelector' },
  {
    type: 'error',
    inputs: [
      { name: 'sender', internalType: 'address', type: 'address' },
      { name: 'expected', internalType: 'address', type: 'address' },
    ],
    name: 'InvalidSender',
  },
  {
    type: 'error',
    inputs: [
      { name: 'received', internalType: 'bytes32', type: 'bytes32' },
      { name: 'expected', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'InvalidWorkflowId',
  },
  {
    type: 'error',
    inputs: [
      { name: 'received', internalType: 'bytes10', type: 'bytes10' },
      { name: 'expected', internalType: 'bytes10', type: 'bytes10' },
    ],
    name: 'InvalidWorkflowName',
  },
  { type: 'error', inputs: [], name: 'LCAlreadyExists' },
  { type: 'error', inputs: [], name: 'LCDoesNotExist' },
  { type: 'error', inputs: [], name: 'NotAuthorized' },
  { type: 'error', inputs: [], name: 'NotIssuingBank' },
  {
    type: 'error',
    inputs: [{ name: 'owner', internalType: 'address', type: 'address' }],
    name: 'OwnableInvalidOwner',
  },
  {
    type: 'error',
    inputs: [{ name: 'account', internalType: 'address', type: 'address' }],
    name: 'OwnableUnauthorizedAccount',
  },
  { type: 'error', inputs: [], name: 'WorkflowNameRequiresAuthorValidation' },
] as const
