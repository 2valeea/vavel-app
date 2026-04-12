# App fee and network fees — notes for Google Play (English)

**Not legal advice.** Have counsel finalize all legal documents and store listings for your entity and jurisdictions.

## In the Send screen (implemented)

Users see **two explicit lines** before continuing: **Service fee (app)** and **Network fee**, plus the longer disclosure and (for ETH/VAVEL) the gas card — so the two concepts are not merged into one vague line.

**First-time consent:** The first time the user taps **Send**, a dialog requires an explicit checkbox acknowledging the **1 VAVEL** service fee (separate from network fees). Acceptance is stored locally (`SharedPreferences` key `vavel_service_fee_consent_v1`). This does not change on-chain fee logic.

## Two separate payments (plain language)

1. **Fixed app service fee — 1 VAVEL (EVM)**  
   Before the main send, the app submits an on-chain transfer of **exactly 1 VAVEL** to **`0xebeaba868348cec64a2712c7d23936af919b09e2`**.  
   This is a **disclosed service fee** for using the in-app send flow. It is **not** the same revenue stream as blockchain miners/validators.

2. **Blockchain network fees**  
   The user also pays standard network fees (e.g. gas) required by the chain. Those fees go to the **network / validators**, not to the app operator.

Both can coexist: you are **not** “taking” miner fees; you are adding a **separate** disclosed on-chain step before the user’s main transaction.

## What was updated in the app (no change to `_performSend` logic)

- **Send screen:** bilingual (RU + EN) notice above the form.  
- **Legal screens (`legal_screens.dart`):** expanded **Terms** and **Privacy** in **English** with clear sections on fees, risks, third parties, warranties, liability caps (where law allows), indemnity, children, international transfers, and placeholders for operator contact / DPO / retention.

## What you must still do with a lawyer

- Add **legal entity name**, **registered address**, **support email**, **governing law / venue**, and any **mandatory consumer rights** text for your countries.  
- List **each SDK** (Firebase, WalletConnect, RPC vendors) and its data practices.  
- Set an **effective date** on the published Privacy Policy and Terms.

## Store listing tip

In the Play Console description or in-app disclosure, use a short line such as:  
**“Two separate costs: (1) a fixed 1 VAVEL app service fee to the operator address shown in-app, and (2) standard blockchain network fees.”**

That reduces confusion and supports transparency.
