Subject: Implementation Smart contact(S) for Letter of Credit settlement

Actors Involved in Letter of Credit Settlement, for simplicity, marked some party as Not in Scope (NIS) at this phase:
  - Applicant ( NIS, let the single issueer provide function to invoke the LC creation ), the party requesting the issuance of the Letter of Credit, typically the buyer in a transaction.
  - Issuing Bank or Trust Holder, responsible for issuing the Letter of Credit and ensuring compliance with its terms.
  - Beneficiary or Seller, the party entitled to receive payment under the Letter of Credit upon fulfillment of its conditions.
  - Advising Bank (NIS, let single issuer conduct all, ignore this function at this phase ), the bank that advises the Beneficiary of the Letter of Credit issuance and may also handle document verification.
  - Confirming Bank(NIS,, let single issuer conduct all, ignore this function at this phase ), an optional bank that adds its guarantee to the Letter of Credit, providing additional security to the Beneficiary.

Busienss Logic for Letter of Credit Settlement:
    There shall be a LocManagement contract to handle the creation, activation, settlement, and expiration of Letters of Credit.
    For each Letter of Credit, a new Loc Contract is created and managed within the LocManagement contract.
    Upon creation of a Letter of Credit, the Issuing Bank invokes the issueLC function, providing necessary details such as LC number, Buyer and Seller account addresses, amount, date of issue, and expiry date.

Data Model:
    A LoC object is created to represent the Letter of Credit, containing fields such as:
    “ uint LCNo; address BuyerAcc; address SellerAcc; uint Amount; bytes2 Status; uint DOIssue; uint DOExpiry; address LCAddress;”

    Status field can have values like "Issued", "Active", "Expired", "Settled".

Functions:
1. issueLC(uint LCNo, address BuyerAcc, address SellerAcc, uint Amount, uint DOIssue, uint DOExpiry): 
   - Invoked by the Issuing Bank to create a new Letter of Credit.
   - Sets the initial status to "Issued".
2. activateLC(uint LCNo): 
   - Invoked by the Issuing Bank to activate the Letter of Credit once all conditions are met.
   - Changes status to "Active".
   - Issuer mint the fund to Ledger address ( here same as issuer's wallet address).
   - Issuer lock the fund in the Ledger smart contract for escrow, allow spending amount to the new Loc contract's address.
3. settleLC(uint LCNo): 
   - Invoked by the Issuing Bank to settle the Letter of Credit upon fulfillment of conditions.
   - Changes status to "Settled" and transfers the specified amount to the Beneficiary's account.
4. expireLC(uint LCNo): 
   - Invoked by the Issuing Bank to mark the Letter of Credit as expired if not settled by the expiry date.
   - Changes status to "Expired".
Events:
- LCIssued(uint LCNo, address BuyerAcc, address SellerAcc, uint Amount);
- LCActivated(uint LCNo);
- LCSettled(uint LCNo);
- LCExpired(uint LCNo);

Treasurey Management:
- Ensure that funds for the Letter of Credit are securely held in escrow until settlement.
- Implement mechanisms for fund release upon successful settlement of the Letter of Credit. An example implentaton by TreasureLedger.sol: using smart contract escrow functionality, 

Flow of Actions:

1. The Applicant requests the Issuing Bank to issue a Letter of Credit.
2. The Issuing Bank invokes issueLC() to create the Letter of Credit.
3. Once the conditions are met, the Issuing Bank invokes activateLC() to activate the Letter of Credit.
4. Upon fulfillment of the conditions by the Beneficiary, Buyer can invokes settleLC() to auto settle the Letter of Credit.
5. If the Letter of Credit is not settled by the expiry date, the Issuing Bank invokes expireLC() to mark it as expired.


Security Considerations:
- Ensure that only authorized Issuing Bank can invoke functions related to Letter of Credit management.
- Validate all input parameters to prevent unauthorized access or manipulation of Letter of Credit data.
- Implement proper logging and auditing mechanisms for all actions taken on Letters of Credit.

Compliance and Regulatory Considerations(NIS):
- Ensure that the implementation complies with relevant financial regulations and standards governing Letters of Credit.
- Maintain records of all Letter of Credit transactions for audit purposes.
- Implement necessary KYC (Know Your Customer) and AML (Anti-Money Laundering) checks as required by jurisdiction.

Testing and Validation:
- Develop comprehensive test cases to validate the functionality of each function related to Letter of Credit management.
- Perform security testing to ensure that only authorized parties can access and modify Letter of Credit data.
- Conduct performance testing to ensure the system can handle the expected volume of Letter of Credit transactions.

Documentation:
- Provide detailed documentation for each function, including input parameters, expected behavior, and potential error conditions.
- Include examples of how to use the Letter of Credit functions in various scenarios.
- Maintain a changelog to track updates and modifications to the Letter of Credit implementation.

Deployment Considerations(NIS):
- Ensure that the deployment environment is secure and compliant with relevant regulations.
- Monitor the system post-deployment to ensure proper functioning and address any issues promptly.
- Plan for regular updates and maintenance to address any bugs or security vulnerabilities that may arise.

## Implentation Reference

### Flow of Letter of Credit activation with sufficient fund balance and allowance:

Issue LC
  ↓
Issuing Bank approves TreasureLedger
  ↓
activateLC() checks:
  ✓ Balance >= LC amount
  ✓ Allowance >= LC amount
  ↓
If both pass → LC becomes Active

### Flow of Letter of Credit settlement:

Issue LC → Seller wants payment
  ↓
Issuing Bank approves Loc contract (TreasureLedger.approve)
  ↓
activateLC() validates approval & sets status to Active
  ↓
Seller calls settleLC() 
  → Loc uses transferFrom to move funds from issuing bank → seller