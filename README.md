# 🏠 Real Estate Tokenizer – Fractional Ownership Smart Contract

A decentralized protocol for **fractionalizing real estate into tradeable security tokens**, enabling fractional investment, governance, and income distribution for tokenized property assets. Built for a world where tokenized securities are projected to exceed **$50B+** and real-world assets are increasingly integrated on-chain.

---

## 🔍 Overview

This smart contract facilitates:

- 📦 Tokenized real estate listings
- 👥 KYC-verified fractional ownership
- 💸 Rental income distribution
- 🔒 Lockups and investor compliance
- 🗳 Property-level governance voting

---

## ⚙️ Core Features

| Feature                         | Description                                                                   |
|----------------------------------|-------------------------------------------------------------------------------|
| 🏗 Property Listing             | Verified managers can tokenize real assets into STX-backed shares            |
| 📈 Fractional Shares            | Investors buy shares with built-in dividend and voting rights                |
| 🔍 KYC/AML Compliance           | Investor verification with expiry and accreditation support                  |
| 💰 Income Distribution          | Rental income is distributed to shareholders based on shareholding           |
| 🔒 Lockup Enforcement           | 60-day lockup prevents premature transfer of shares                           |
| 🧾 Dividend Claim System        | Claimable by eligible shareholders post-distribution                          |
| 🗳 Governance Proposals         | Shareholders vote on major decisions (renovation, refinance, sale)           |
| 🎫 NFT Certificate              | Ownership NFT minted for each listed property                                 |

---

## 🧾 Constants & Parameters

| Constant             | Value       | Description                               |
|----------------------|-------------|-------------------------------------------|
| `min-investment`     | 1000 STX    | Minimum required to participate           |
| `lockup-period`      | ~60 days    | Restricts transfer after purchase         |
| `management-fee`     | 2% annually | Auto-deducted from income distributions   |
| `max-shareholders`   | 500         | Cap per property                          |

---

## 📌 Key Contract Components

### 📦 Property Listing

```clojure
(list-property address type valuation shares income expenses compliance-hash)
````

* Tokenizes a new property
* Sets share price automatically
* Requires KYC-verified management principal
* Mints an NFT certificate

---

### 💳 Share Purchase

```clojure
(buy-shares property-id shares)
```

* Checks investor KYC and lockup conditions
* Validates accredited investor status for commercial properties
* Transfers STX and mints shares to buyer

---

### 🔄 Share Transfer

```clojure
(transfer-shares property-id to shares)
```

* Permitted after lockup
* Receiver must pass KYC & be accredited (for commercial)
* Updates both sender and receiver share records

---

### 💸 Income Distribution

```clojure
(distribute-income property-id period income other-income expenses)
```

* Calculates net income and management fee
* Stores per-period income record
* Only callable by the property manager

---

### 📥 Claim Dividends

```clojure
(claim-dividends property-id period)
```

* Each shareholder claims pro-rata dividend
* Distributes in STX based on ownership
* Prevents double claims

---

### ✅ Register for KYC

```clojure
(register-kyc country accredited?)
```

* Simulates off-chain KYC check
* Flags accreditation for commercial investments
* Sets a 1-year KYC expiration

---

### 🧠 Governance Ready (Coming Soon)

* Proposal voting for decisions like:

  * Renovations
  * Refinancing
  * Selling the property
* Share-weighted voting with quorum and deadlines

---

## 🛡 Security & Compliance

| Mechanism                 | Purpose                                      |
| ------------------------- | -------------------------------------------- |
| **KYC & AML Registry**    | Prevents unauthorized or high-risk investors |
| **Lockup Period**         | Mitigates pump-dump and premature liquidity  |
| **Transfer Restrictions** | Complies with accredited-only offerings      |
| **Income Tracking**       | Ensures clear accounting and dividend logic  |

---

## 📚 Read-Only Functions

| Function                   | Description                           |
| -------------------------- | ------------------------------------- |
| `get-property`             | View a property's metadata            |
| `get-shareholder-info`     | View ownership details per user       |
| `is-kyc-verified`          | Check if user has valid KYC record    |
| `calculate-dividend-share` | Preview a user's dividend entitlement |

---

## 📈 Performance Metrics

| Variable                | Description                               |
| ----------------------- | ----------------------------------------- |
| `total-properties`      | Number of tokenized properties            |
| `total-value-tokenized` | Cumulative value of all property listings |
| `dividends-distributed` | Total STX distributed to all shareholders |

---

## 🧠 Smart Architecture Highlights

* Modular mappings for properties, shareholders, and income
* NFT-backed ownership for enhanced traceability
* Built-in dividend payout flow
* Legal/compliance-aware enforcement baked in

---

## 🏗 Suggested Future Enhancements

* ✅ Chainlink oracles for property appraisal
* 🔁 Secondary market for trading shares
* 🏦 Integration with stablecoins for yield
* 📲 Mobile dashboard for investor tracking

---

## 📜 License

MIT — Innovate freely while building a compliant, fractional real estate future.

---

## 🤝 Inspired By

* RealT (Ethereum)
* Lofty (Algorand)
* SEC Reg D / Reg A compliant offerings
* Tokeny and Vertalo RWA frameworks
