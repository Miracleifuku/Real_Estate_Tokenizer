;; Real Estate Tokenizer - Property Fractional Ownership
;; Addressing tokenized securities surpassing $50B and real-world asset integration
;; Platform for fractionalizing real estate into tradeable security tokens

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-property-exists (err u1500))
(define-constant err-invalid-property (err u1501))
(define-constant err-kyc-required (err u1502))
(define-constant err-insufficient-shares (err u1503))
(define-constant err-transfer-restricted (err u1504))
(define-constant err-not-accredited (err u1505))
(define-constant err-dividend-pending (err u1506))
(define-constant err-vote-active (err u1507))

;; Property parameters
(define-constant min-investment u1000000000) ;; 1000 STX minimum
(define-constant lockup-period u8640) ;; 60 days
(define-constant management-fee u200) ;; 2% annual
(define-constant min-shareholders u10)
(define-constant max-shareholders u500)

;; Data Variables
(define-data-var total-properties uint u0)
(define-data-var total-value-tokenized uint u0)
(define-data-var dividends-distributed uint u0)

;; NFT for property ownership certificate
(define-non-fungible-token property-certificate uint)

;; Maps
(define-map properties
    uint ;; property-id
    {
        address: (string-ascii 200),
        property-type: (string-ascii 20), ;; "residential", "commercial", "industrial"
        valuation: uint,
        total-shares: uint,
        available-shares: uint,
        share-price: uint,
        rental-income: uint,
        expenses: uint,
        management-company: principal,
        listing-date: uint,
        is-active: bool,
        compliance-hash: (buff 32)
    }
)

(define-map shareholders
    {property-id: uint, shareholder: principal}
    {
        shares-owned: uint,
        investment-amount: uint,
        purchase-date: uint,
        locked-until: uint,
        dividends-earned: uint,
        voting-power: uint,
        is-accredited: bool
    }
)

(define-map kyc-registry
    principal
    {
        verified: bool,
        verification-date: uint,
        country: (string-ascii 2),
        accredited-investor: bool,
        aml-cleared: bool,
        expires: uint
    }
)

(define-map property-income
    {property-id: uint, period: uint}
    {
        rental-income: uint,
        other-income: uint,
        operating-expenses: uint,
        management-fees: uint,
        net-income: uint,
        distributed: bool
    }
)

(define-map governance-proposals
    {property-id: uint, proposal-id: uint}
    {
        proposer: principal,
        proposal-type: (string-ascii 20), ;; "renovation", "sale", "refinance"
        description: (string-utf8 500),
        amount-requested: uint,
        votes-for: uint,
        votes-against: uint,
        voting-deadline: uint,
        executed: bool
    }
)

;; Helper functions
(define-private (min (a uint) (b uint))
    (if (< a b) a b)
)

(define-private (max (a uint) (b uint))
    (if (> a b) a b)
)

;; Read-only functions
(define-read-only (get-property (property-id uint))
    (map-get? properties property-id)
)

(define-read-only (get-shareholder-info (property-id uint) (shareholder principal))
    (map-get? shareholders {property-id: property-id, shareholder: shareholder})
)

(define-read-only (is-kyc-verified (user principal))
    (match (map-get? kyc-registry user)
        kyc-data (and (get verified kyc-data) 
                     (< stacks-block-height (get expires kyc-data)))
        false)
)

(define-read-only (calculate-dividend-share (property-id uint) (shareholder principal))
    (let (
        (shareholder-data (get-shareholder-info property-id shareholder))
        (property (get-property property-id))
    )
        (match shareholder-data
            s-data (match property
                p-data (/ (* (get rental-income p-data) (get shares-owned s-data)) 
                         (get total-shares p-data))
                u0)
            u0)
    )
)

;; Public functions

;; List new property
(define-public (list-property
    (address (string-ascii 200))
    (property-type (string-ascii 20))
    (valuation uint)
    (total-shares uint)
    (rental-income uint)
    (expenses uint)
    (compliance-hash (buff 32)))
    (let (
        (property-id (+ (var-get total-properties) u1))
        (share-price (/ valuation total-shares))
    )
        ;; Only verified management companies can list
        (asserts! (is-kyc-verified tx-sender) err-kyc-required)
        (asserts! (> valuation u0) err-invalid-property)
        (asserts! (>= total-shares u1000) err-invalid-property) ;; Min 1000 shares
        
        ;; Mint property certificate NFT
        (try! (nft-mint? property-certificate property-id tx-sender))
        
        ;; Create property listing
        (map-set properties property-id {
            address: address,
            property-type: property-type,
            valuation: valuation,
            total-shares: total-shares,
            available-shares: total-shares,
            share-price: share-price,
            rental-income: rental-income,
            expenses: expenses,
            management-company: tx-sender,
            listing-date: stacks-block-height,
            is-active: true,
            compliance-hash: compliance-hash
        })
        
        (var-set total-properties property-id)
        (var-set total-value-tokenized (+ (var-get total-value-tokenized) valuation))
        
        (ok property-id)
    )
)

;; Buy property shares
(define-public (buy-shares
    (property-id uint)
    (shares uint))
    (let (
        (property (unwrap! (get-property property-id) err-invalid-property))
        (kyc-data (unwrap! (map-get? kyc-registry tx-sender) err-kyc-required))
        (total-cost (* shares (get share-price property)))
        (shareholder-count (count-shareholders property-id))
    )
        (asserts! (get verified kyc-data) err-kyc-required)
        (asserts! (get is-active property) err-invalid-property)
        (asserts! (<= shares (get available-shares property)) err-insufficient-shares)
        (asserts! (>= total-cost min-investment) err-insufficient-shares)
        (asserts! (< shareholder-count max-shareholders) err-transfer-restricted)
        
        ;; For certain property types, require accredited investor status
        (if (is-eq (get property-type property) "commercial")
            (asserts! (get accredited-investor kyc-data) err-not-accredited)
            true)
        
        ;; Transfer payment
        (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
        
        ;; Update or create shareholder record
        (match (get-shareholder-info property-id tx-sender)
            existing (map-set shareholders {property-id: property-id, shareholder: tx-sender} {
                shares-owned: (+ (get shares-owned existing) shares),
                investment-amount: (+ (get investment-amount existing) total-cost),
                purchase-date: (get purchase-date existing),
                locked-until: (max (get locked-until existing) (+ stacks-block-height lockup-period)),
                dividends-earned: (get dividends-earned existing),
                voting-power: (+ (get shares-owned existing) shares),
                is-accredited: (get accredited-investor kyc-data)
            })
            (map-set shareholders {property-id: property-id, shareholder: tx-sender} {
                shares-owned: shares,
                investment-amount: total-cost,
                purchase-date: stacks-block-height,
                locked-until: (+ stacks-block-height lockup-period),
                dividends-earned: u0,
                voting-power: shares,
                is-accredited: (get accredited-investor kyc-data)
            })
        )
        
        ;; Update property
        (map-set properties property-id (merge property {
            available-shares: (- (get available-shares property) shares)
        }))
        
        (ok shares)
    )
)

;; Transfer shares (with restrictions)
(define-public (transfer-shares
    (property-id uint)
    (to principal)
    (shares uint))
    (let (
        (from-data (unwrap! (get-shareholder-info property-id tx-sender) err-insufficient-shares))
        (to-kyc (unwrap! (map-get? kyc-registry to) err-kyc-required))
        (property (unwrap! (get-property property-id) err-invalid-property))
    )
        (asserts! (>= (get shares-owned from-data) shares) err-insufficient-shares)
        (asserts! (> stacks-block-height (get locked-until from-data)) err-transfer-restricted)
        (asserts! (get verified to-kyc) err-kyc-required)
        
        ;; Check accreditation requirements
        (if (is-eq (get property-type property) "commercial")
            (asserts! (get accredited-investor to-kyc) err-not-accredited)
            true)
        
        ;; Update from shareholder
        (map-set shareholders {property-id: property-id, shareholder: tx-sender} (merge from-data {
            shares-owned: (- (get shares-owned from-data) shares),
            voting-power: (- (get voting-power from-data) shares)
        }))
        
        ;; Update to shareholder
        (match (get-shareholder-info property-id to)
            existing (map-set shareholders {property-id: property-id, shareholder: to} {
                shares-owned: (+ (get shares-owned existing) shares),
                investment-amount: (get investment-amount existing),
                purchase-date: (get purchase-date existing),
                locked-until: (get locked-until existing),
                dividends-earned: (get dividends-earned existing),
                voting-power: (+ (get voting-power existing) shares),
                is-accredited: (get accredited-investor to-kyc)
            })
            (map-set shareholders {property-id: property-id, shareholder: to} {
                shares-owned: shares,
                investment-amount: u0,
                purchase-date: stacks-block-height,
                locked-until: stacks-block-height,
                dividends-earned: u0,
                voting-power: shares,
                is-accredited: (get accredited-investor to-kyc)
            })
        )
        
        (ok true)
    )
)

;; Distribute rental income
(define-public (distribute-income
    (property-id uint)
    (period uint)
    (rental-income uint)
    (other-income uint)
    (operating-expenses uint))
    (let (
        (property (unwrap! (get-property property-id) err-invalid-property))
        (management-fees (/ (* (+ rental-income other-income) management-fee) u10000))
        (net-income (- (+ rental-income other-income) (+ operating-expenses management-fees)))
    )
        (asserts! (is-eq (get management-company property) tx-sender) err-kyc-required)
        
        ;; Record income
        (map-set property-income {property-id: property-id, period: period} {
            rental-income: rental-income,
            other-income: other-income,
            operating-expenses: operating-expenses,
            management-fees: management-fees,
            net-income: net-income,
            distributed: false
        })
        
        ;; Update property income
        (map-set properties property-id (merge property {
            rental-income: rental-income,
            expenses: operating-expenses
        }))
        
        (var-set dividends-distributed (+ (var-get dividends-distributed) net-income))
        
        (ok net-income)
    )
)

;; Claim dividends
(define-public (claim-dividends (property-id uint) (period uint))
    (let (
        (income-data (unwrap! (map-get? property-income {property-id: property-id, period: period}) 
                             err-dividend-pending))
        (shareholder-data (unwrap! (get-shareholder-info property-id tx-sender) err-insufficient-shares))
        (property (unwrap! (get-property property-id) err-invalid-property))
        (dividend-amount (/ (* (get net-income income-data) (get shares-owned shareholder-data)) 
                           (get total-shares property)))
    )
        (asserts! (not (get distributed income-data)) err-dividend-pending)
        (asserts! (> dividend-amount u0) err-insufficient-shares)
        
        ;; Transfer dividend
        (try! (as-contract (stx-transfer? dividend-amount tx-sender tx-sender)))
        
        ;; Update shareholder
        (map-set shareholders {property-id: property-id, shareholder: tx-sender} (merge shareholder-data {
            dividends-earned: (+ (get dividends-earned shareholder-data) dividend-amount)
        }))
        
        (ok dividend-amount)
    )
)

;; Register for KYC
(define-public (register-kyc
    (country (string-ascii 2))
    (accredited bool))
    (begin
        ;; In production, this would verify identity through oracle
        (map-set kyc-registry tx-sender {
            verified: true,
            verification-date: stacks-block-height,
            country: country,
            accredited-investor: accredited,
            aml-cleared: true,
            expires: (+ stacks-block-height u52560) ;; 1 year
        })
        
        (ok true)
    )
)

;; Private functions
(define-private (count-shareholders (property-id uint))
    ;; Simplified - would count actual shareholders
    u50
)