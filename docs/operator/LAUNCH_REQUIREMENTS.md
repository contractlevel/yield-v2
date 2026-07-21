# Launch Requirements

The following are non-negotiable requirements for a production launch. The commercial operator owns completion of each item and must retain written evidence of approval.

These are launch gates, not technical deployment steps. Production must not open to users until all four are complete for the version and operating model being launched.

## 1. Independent security review

- [ ] Commission an external audit or equivalent independent security review of the production release.
- [ ] Resolve every finding, or formally document why any remaining finding is accepted.
- [ ] Confirm that the reviewed scope matches the contracts, workflow, integrations, configuration, and deployment process intended for launch.

**Why:** The protocol holds user assets and depends on privileged configuration, external strategies, CRE, CCIP, and ACE. An independent review provides assurance beyond the development team's own testing and makes any accepted security risk explicit.

## 2. Legal and regulatory approval

- [ ] Obtain a written legal opinion approving the proposed launch and operating model.
- [ ] Ask counsel to define the permitted jurisdictions, users, marketing, disclosures, terms, and compliance controls.
- [ ] Confirm any required registrations, licences, KYC/AML and sanctions processes, privacy obligations, and ongoing reporting or record-keeping duties.
- [ ] Ensure the implemented ACE policies and the operator's procedures reflect counsel's requirements.

**Why:** The legal treatment of the product, share token, yield activity, and operator obligations depends on how and where the protocol is offered. Smart-contract controls support the compliance model, but they do not determine or replace the operator's legal obligations.

## 3. Chainlink ACE production licence

- [ ] Contact Chainlink and obtain the licence grant required to use the Chainlink ACE contracts in production.
- [ ] Have counsel review the applicable ACE licence terms and confirm that the planned use is covered.
- [ ] Retain the executed grant and record any restrictions, reporting duties, expiry dates, or renewal requirements.

Chainlink directed the protocol author to begin this process through [chain.link/contact](https://chain.link/contact).

**Why:** The public Chainlink ACE repository is licensed under BUSL-1.1. A production or commercial use grant must be confirmed with Chainlink before launch; access to the source code alone is not production authorisation.

## 4. Agreement with the protocol author

- [ ] Enter into a written agreement with the protocol author and owner before operating or commercially launching the protocol.
- [ ] Clearly define the operator's authority, responsibilities, service standards, fees or revenue share, and permitted use of the protocol and its intellectual property.
- [ ] Allocate responsibility for compliance, security, administration, incidents, losses, insurance, disclosures, third-party services, and ongoing maintenance.
- [ ] Define the term, termination rights, dispute process, and orderly handover of infrastructure.
- [ ] Have counsel for each party review and approve the final agreement.

**Why:** The operator needs explicit authority from the protocol owner and a clear allocation of commercial and operational responsibility. A written agreement protects both parties and reduces ambiguity over control, economics, liability, intellectual property, and what happens when the relationship ends.

## Final approval

- [ ] Record a formal go-live decision confirming that all requirements above are complete, their evidence is stored, and no material change has been made since the security and legal reviews.

If the release, supported jurisdictions, compliance model, or material third-party integration changes before launch, the operator must return the affected requirement to review for confirmation.
