;; title: Decentralized Exchange (DEX)
;; version: 1.0.0
;; summary: A full-featured DEX with AMM, liquidity pools, and staking rewards
;; description: Enables token swaps, liquidity provision, and reward distribution for SIP-010 tokens

;; traits
(define-trait sip-010-trait (
  (transfer
    (uint principal principal (optional (buff 34)))
    (response bool uint)
  )
  (get-name
    ()
    (response (string-ascii 32) uint)
  )
  (get-symbol
    ()
    (response (string-ascii 32) uint)
  )
  (get-decimals
    ()
    (response uint uint)
  )
  (get-balance
    (principal)
    (response uint uint)
  )
  (get-total-supply
    ()
    (response uint uint)
  )
  (get-token-uri
    ()
    (response (optional (string-utf8 256)) uint)
  )
))

;; token definitions
(define-fungible-token lp-token)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-pool-exists (err u101))
(define-constant err-pool-not-found (err u102))
(define-constant err-insufficient-liquidity (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-slippage-exceeded (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-same-token (err u107))
(define-constant err-reentrancy (err u108))
(define-constant err-math-overflow (err u109))
(define-constant err-token-transfer (err u110))

(define-constant fee-rate u300) ;; 0.3% = 300/100000
(define-constant fee-denominator u100000)
(define-constant minimum-liquidity u1000)

;; data vars
(define-data-var total-pools uint u0)
(define-data-var reentrancy-guard bool false)
(define-data-var reward-rate uint u100) ;; rewards per block per LP token

;; data maps
(define-map pools
  {
    token-a: principal,
    token-b: principal,
  }
  {
    reserve-a: uint,
    reserve-b: uint,
    total-supply: uint,
    last-reward-block: uint,
    accumulated-reward-per-share: uint,
  }
)

(define-map liquidity-providers
  {
    pool: {
      token-a: principal,
      token-b: principal,
    },
    provider: principal,
  }
  {
    amount: uint,
    reward-debt: uint,
    last-claim-block: uint,
  }
)

(define-map user-pools
  principal
  (list 50 {
    token-a: principal,
    token-b: principal,
  })
)

(define-map pending-rewards
  principal
  uint
)

;; private functions

;; Safe math operations
(define-private (min
    (a uint)
    (b uint)
  )
  (if (<= a b)
    a
    b
  )
)

(define-private (max
    (a uint)
    (b uint)
  )
  (if (>= a b)
    a
    b
  )
)

;; Reentrancy protection modifier
(define-private (check-reentrancy)
  (begin
    (asserts! (not (var-get reentrancy-guard)) err-reentrancy)
    (var-set reentrancy-guard true)
    (ok true)
  )
)

(define-private (clear-reentrancy)
  (var-set reentrancy-guard false)
)

;; Helper function to get ordered token pair (simple deterministic ordering)
(define-private (get-token-pair
    (token-a principal)
    (token-b principal)
  )
  (let (
      (buff-a (unwrap-panic (to-consensus-buff? token-a)))
      (buff-b (unwrap-panic (to-consensus-buff? token-b)))
    )
    (if (<= (len buff-a) (len buff-b))
      {
        token-a: token-a,
        token-b: token-b,
      }
      {
        token-a: token-b,
        token-b: token-a,
      }
    )
  )
)

;; Validate that a token contract implements SIP-010
(define-private (validate-token-contract (token-contract <sip-010-trait>))
  (let ((token-principal (contract-of token-contract)))
    (and
      (is-standard token-principal)
      (not (is-eq token-principal (as-contract tx-sender)))
    )
  )
)

;; Validate numeric inputs are within reasonable bounds
(define-private (validate-amount (amount uint))
  (and (> amount u0) (< amount u340282366920938463463374607431768211455))
)

;; Validate slippage parameters
(define-private (validate-slippage
    (amount-desired uint)
    (amount-min uint)
  )
  (and
    (validate-amount amount-desired)
    (validate-amount amount-min)
    (<= amount-min amount-desired)
  )
)

;; Update reward calculations for a pool
(define-private (update-pool-rewards (pool-key {
  token-a: principal,
  token-b: principal,
}))
  (let (
      (pool-data (unwrap! (map-get? pools pool-key) err-pool-not-found))
      (last-reward-block (get last-reward-block pool-data))
      (total-supply (get total-supply pool-data))
      (blocks-elapsed (- stacks-block-height last-reward-block))
    )
    (if (and (> blocks-elapsed u0) (> total-supply u0))
      (let (
          (reward-per-block (var-get reward-rate))
          (total-rewards (* blocks-elapsed reward-per-block))
          (reward-per-share (/ (* total-rewards u1000000) total-supply))
          (new-accumulated (+ (get accumulated-reward-per-share pool-data) reward-per-share))
        )
        (map-set pools pool-key
          (merge pool-data {
            last-reward-block: stacks-block-height,
            accumulated-reward-per-share: new-accumulated,
          })
        )
        (ok new-accumulated)
      )
      (ok (get accumulated-reward-per-share pool-data))
    )
  )
)

;; Calculate pending rewards for a liquidity provider
(define-private (calculate-pending-rewards
    (pool-key {
      token-a: principal,
      token-b: principal,
    })
    (provider principal)
  )
  (match (map-get? pools pool-key)
    pool-data (let (
        (provider-key {
          pool: pool-key,
          provider: provider,
        })
        (provider-data (map-get? liquidity-providers provider-key))
      )
      (match provider-data
        lp-info (let (
            (lp-amount (get amount lp-info))
            (reward-debt (get reward-debt lp-info))
            (accumulated-reward-per-share (get accumulated-reward-per-share pool-data))
            (pending (* lp-amount accumulated-reward-per-share))
          )
          (if (> pending reward-debt)
            (/ (- pending reward-debt) u1000000)
            u0
          )
        )
        u0
      )
    )
    u0
  )
)

;; public functions

;; Create a new liquidity pool
(define-public (create-pool
    (token-a-contract <sip-010-trait>)
    (token-b-contract <sip-010-trait>)
  )
  (let (
      (token-a (contract-of token-a-contract))
      (token-b (contract-of token-b-contract))
      (pool-key (get-token-pair token-a token-b))
    )
    (begin
      (try! (check-reentrancy))
      ;; Validate token contracts
      (asserts! (validate-token-contract token-a-contract) err-invalid-amount)
      (asserts! (validate-token-contract token-b-contract) err-invalid-amount)
      (asserts! (not (is-eq token-a token-b)) err-same-token)
      (asserts! (is-none (map-get? pools pool-key)) err-pool-exists)
      (map-set pools pool-key {
        reserve-a: u0,
        reserve-b: u0,
        total-supply: u0,
        last-reward-block: stacks-block-height,
        accumulated-reward-per-share: u0,
      })
      (var-set total-pools (+ (var-get total-pools) u1))
      (clear-reentrancy)
      (ok pool-key)
    )
  )
)

;; Add liquidity to a pool
(define-public (add-liquidity
    (token-a-contract <sip-010-trait>)
    (token-b-contract <sip-010-trait>)
    (amount-a-desired uint)
    (amount-b-desired uint)
    (amount-a-min uint)
    (amount-b-min uint)
  )
  (let (
      (token-a (contract-of token-a-contract))
      (token-b (contract-of token-b-contract))
      (pool-key (get-token-pair token-a token-b))
      (pool-data (unwrap! (map-get? pools pool-key) err-pool-not-found))
      (reserve-a (get reserve-a pool-data))
      (reserve-b (get reserve-b pool-data))
      (total-supply (get total-supply pool-data))
    )
    (begin
      (try! (check-reentrancy))
      ;; Validate token contracts
      (asserts! (validate-token-contract token-a-contract) err-invalid-amount)
      (asserts! (validate-token-contract token-b-contract) err-invalid-amount)
      ;; Validate input amounts and slippage
      (asserts! (validate-slippage amount-a-desired amount-a-min)
        err-invalid-amount
      )
      (asserts! (validate-slippage amount-b-desired amount-b-min)
        err-invalid-amount
      )
      (let (
          (amounts (if (and (is-eq reserve-a u0) (is-eq reserve-b u0))
            ;; First liquidity provision
            {
              amount-a: amount-a-desired,
              amount-b: amount-b-desired,
            }
            ;; Calculate optimal amounts based on existing reserves
            (let (
                (amount-b-optimal (/ (* amount-a-desired reserve-b) reserve-a))
                (amount-a-optimal (/ (* amount-b-desired reserve-a) reserve-b))
              )
              (if (<= amount-b-optimal amount-b-desired)
                (begin
                  (asserts! (>= amount-b-optimal amount-b-min)
                    err-slippage-exceeded
                  )
                  {
                    amount-a: amount-a-desired,
                    amount-b: amount-b-optimal,
                  }
                )
                (begin
                  (asserts! (>= amount-a-optimal amount-a-min)
                    err-slippage-exceeded
                  )
                  {
                    amount-a: amount-a-optimal,
                    amount-b: amount-b-desired,
                  }
                )
              )
            )
          ))
          (amount-a (get amount-a amounts))
          (amount-b (get amount-b amounts))
          (liquidity (if (is-eq total-supply u0)
            (let ((product (* amount-a amount-b)))
              (if (> product (* minimum-liquidity minimum-liquidity))
                (- product minimum-liquidity)
                u0
              )
            )
            (min (/ (* amount-a total-supply) reserve-a)
              (/ (* amount-b total-supply) reserve-b)
            )
          ))
        )
        (asserts! (> liquidity u0) err-insufficient-liquidity)
        ;; Transfer tokens from user
        (try! (contract-call? token-a-contract transfer amount-a tx-sender
          (as-contract tx-sender) none
        ))
        (try! (contract-call? token-b-contract transfer amount-b tx-sender
          (as-contract tx-sender) none
        ))
        ;; Mint LP tokens
        (try! (ft-mint? lp-token liquidity tx-sender))
        ;; Update pool reserves
        (map-set pools pool-key
          (merge pool-data {
            reserve-a: (+ reserve-a amount-a),
            reserve-b: (+ reserve-b amount-b),
            total-supply: (+ total-supply liquidity),
          })
        )
        ;; Update liquidity provider info
        (let (
            (provider-key {
              pool: pool-key,
              provider: tx-sender,
            })
            (current-lp (default-to {
              amount: u0,
              reward-debt: u0,
              last-claim-block: stacks-block-height,
            }
              (map-get? liquidity-providers provider-key)
            ))
          )
          (map-set liquidity-providers provider-key
            (merge current-lp {
              amount: (+ (get amount current-lp) liquidity),
              last-claim-block: stacks-block-height,
            })
          )
        )
        (clear-reentrancy)
        (ok {
          amount-a: amount-a,
          amount-b: amount-b,
          liquidity: liquidity,
        })
      )
    )
  )
)

;; Remove liquidity from a pool
(define-public (remove-liquidity
    (token-a-contract <sip-010-trait>)
    (token-b-contract <sip-010-trait>)
    (liquidity uint)
    (amount-a-min uint)
    (amount-b-min uint)
  )
  (let (
      (token-a (contract-of token-a-contract))
      (token-b (contract-of token-b-contract))
      (pool-key (get-token-pair token-a token-b))
      (pool-data (unwrap! (map-get? pools pool-key) err-pool-not-found))
      (reserve-a (get reserve-a pool-data))
      (reserve-b (get reserve-b pool-data))
      (total-supply (get total-supply pool-data))
    )
    (begin
      (try! (check-reentrancy))
      ;; Validate token contracts
      (asserts! (validate-token-contract token-a-contract) err-invalid-amount)
      (asserts! (validate-token-contract token-b-contract) err-invalid-amount)
      ;; Validate amounts
      (asserts! (validate-amount liquidity) err-invalid-amount)
      (asserts! (validate-amount amount-a-min) err-invalid-amount)
      (asserts! (validate-amount amount-b-min) err-invalid-amount)
      (asserts! (> total-supply u0) err-insufficient-liquidity)
      (let (
          (amount-a (/ (* liquidity reserve-a) total-supply))
          (amount-b (/ (* liquidity reserve-b) total-supply))
        )
        (asserts! (>= amount-a amount-a-min) err-slippage-exceeded)
        (asserts! (>= amount-b amount-b-min) err-slippage-exceeded)
        ;; Burn LP tokens
        (try! (ft-burn? lp-token liquidity tx-sender))
        ;; Transfer tokens to user
        (try! (as-contract (contract-call? token-a-contract transfer amount-a tx-sender tx-sender
          none
        )))
        (try! (as-contract (contract-call? token-b-contract transfer amount-b tx-sender tx-sender
          none
        )))
        ;; Update pool reserves
        (map-set pools pool-key
          (merge pool-data {
            reserve-a: (- reserve-a amount-a),
            reserve-b: (- reserve-b amount-b),
            total-supply: (- total-supply liquidity),
          })
        )
        ;; Update liquidity provider info
        (let (
            (provider-key {
              pool: pool-key,
              provider: tx-sender,
            })
            (current-lp (unwrap! (map-get? liquidity-providers provider-key)
              err-insufficient-balance
            ))
          )
          (asserts! (>= (get amount current-lp) liquidity)
            err-insufficient-balance
          )
          (map-set liquidity-providers provider-key
            (merge current-lp { amount: (- (get amount current-lp) liquidity) })
          )
        )
        (clear-reentrancy)
        (ok {
          amount-a: amount-a,
          amount-b: amount-b,
        })
      )
    )
  )
)

;; Swap tokens using AMM (xy=k) formula
(define-public (swap-tokens
    (token-in-contract <sip-010-trait>)
    (token-out-contract <sip-010-trait>)
    (amount-in uint)
    (amount-out-min uint)
  )
  (let (
      (token-in (contract-of token-in-contract))
      (token-out (contract-of token-out-contract))
      (pool-key (get-token-pair token-in token-out))
      (pool-data (unwrap! (map-get? pools pool-key) err-pool-not-found))
      (is-token-a-in (is-eq token-in (get token-a pool-key)))
    )
    (begin
      (try! (check-reentrancy))
      ;; Validate token contracts
      (asserts! (validate-token-contract token-in-contract) err-invalid-amount)
      (asserts! (validate-token-contract token-out-contract) err-invalid-amount)
      ;; Validate amounts
      (asserts! (validate-amount amount-in) err-invalid-amount)
      (asserts! (validate-amount amount-out-min) err-invalid-amount)
      (asserts! (not (is-eq token-in token-out)) err-same-token)
      (let (
          (reserve-in (if is-token-a-in
            (get reserve-a pool-data)
            (get reserve-b pool-data)
          ))
          (reserve-out (if is-token-a-in
            (get reserve-b pool-data)
            (get reserve-a pool-data)
          ))
          (amount-in-with-fee (- amount-in (/ (* amount-in fee-rate) fee-denominator)))
          (numerator (* amount-in-with-fee reserve-out))
          (denominator (+ reserve-in amount-in-with-fee))
          (amount-out (/ numerator denominator))
        )
        (asserts! (> reserve-in u0) err-insufficient-liquidity)
        (asserts! (> reserve-out u0) err-insufficient-liquidity)
        (asserts! (> amount-out u0) err-insufficient-liquidity)
        (asserts! (>= amount-out amount-out-min) err-slippage-exceeded)
        ;; Transfer input token from user
        (try! (contract-call? token-in-contract transfer amount-in tx-sender
          (as-contract tx-sender) none
        ))
        ;; Transfer output token to user
        (try! (as-contract (contract-call? token-out-contract transfer amount-out tx-sender
          tx-sender none
        )))
        ;; Update pool reserves
        (let (
            (new-reserve-a (if is-token-a-in
              (+ (get reserve-a pool-data) amount-in)
              (- (get reserve-a pool-data) amount-out)
            ))
            (new-reserve-b (if is-token-a-in
              (- (get reserve-b pool-data) amount-out)
              (+ (get reserve-b pool-data) amount-in)
            ))
          )
          (map-set pools pool-key
            (merge pool-data {
              reserve-a: new-reserve-a,
              reserve-b: new-reserve-b,
            })
          )
        )
        (clear-reentrancy)
        (ok {
          amount-in: amount-in,
          amount-out: amount-out,
        })
      )
    )
  )
)

;; Claim rewards for liquidity provision
(define-public (claim-rewards
    (token-a-contract <sip-010-trait>)
    (token-b-contract <sip-010-trait>)
  )
  (let (
      (token-a (contract-of token-a-contract))
      (token-b (contract-of token-b-contract))
      (pool-key (get-token-pair token-a token-b))
      (provider-key {
        pool: pool-key,
        provider: tx-sender,
      })
    )
    (begin
      (try! (check-reentrancy))
      ;; Validate token contracts
      (asserts! (validate-token-contract token-a-contract) err-invalid-amount)
      (asserts! (validate-token-contract token-b-contract) err-invalid-amount)
      (try! (update-pool-rewards pool-key))
      (let (
          (pending-reward (calculate-pending-rewards pool-key tx-sender))
          (provider-data (unwrap! (map-get? liquidity-providers provider-key)
            err-insufficient-balance
          ))
          (pool-data (unwrap! (map-get? pools pool-key) err-pool-not-found))
          (lp-amount (get amount provider-data))
          (new-reward-debt (* lp-amount (get accumulated-reward-per-share pool-data)))
        )
        (if (> pending-reward u0)
          (begin
            ;; Mint reward tokens (using LP token as reward for simplicity)
            (try! (ft-mint? lp-token pending-reward tx-sender))
            ;; Update provider's reward debt
            (map-set liquidity-providers provider-key
              (merge provider-data {
                reward-debt: new-reward-debt,
                last-claim-block: stacks-block-height,
              })
            )
            ;; Update user's total pending rewards
            (let ((current-pending (default-to u0 (map-get? pending-rewards tx-sender))))
              (map-set pending-rewards tx-sender
                (+ current-pending pending-reward)
              )
            )
            (clear-reentrancy)
            (ok pending-reward)
          )
          (begin
            (clear-reentrancy)
            (ok u0)
          )
        )
      )
    )
  )
)

;; Set reward rate (only contract owner)
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Validate reward rate is reasonable (not zero, not too high)
    (asserts! (and (> new-rate u0) (< new-rate u1000000)) err-invalid-amount)
    (var-set reward-rate new-rate)
    (ok true)
  )
)

;; read only functions

;; Get pool information
(define-read-only (get-pool-info
    (token-a principal)
    (token-b principal)
  )
  (let ((pool-key (get-token-pair token-a token-b)))
    (map-get? pools pool-key)
  )
)

;; Get liquidity provider information
(define-read-only (get-liquidity-provider-info
    (token-a principal)
    (token-b principal)
    (provider principal)
  )
  (let (
      (pool-key (get-token-pair token-a token-b))
      (provider-key {
        pool: pool-key,
        provider: provider,
      })
    )
    (map-get? liquidity-providers provider-key)
  )
)

;; Calculate swap output amount (for UI estimation)
(define-read-only (get-swap-amount-out
    (token-a principal)
    (token-b principal)
    (amount-in uint)
  )
  (let (
      (pool-key (get-token-pair token-a token-b))
      (pool-data (map-get? pools pool-key))
    )
    (match pool-data
      pool (let (
          (is-token-a-in (is-eq token-a (get token-a pool-key)))
          (reserve-in (if is-token-a-in
            (get reserve-a pool)
            (get reserve-b pool)
          ))
          (reserve-out (if is-token-a-in
            (get reserve-b pool)
            (get reserve-a pool)
          ))
          (amount-in-with-fee (- amount-in (/ (* amount-in fee-rate) fee-denominator)))
          (numerator (* amount-in-with-fee reserve-out))
          (denominator (+ reserve-in amount-in-with-fee))
        )
        (if (and
            (> reserve-in u0)
            (> reserve-out u0)
            (> amount-in u0)
          )
          (some (/ numerator denominator))
          none
        )
      )
      none
    )
  )
)

;; Calculate input amount needed for desired output (for UI estimation)
(define-read-only (get-swap-amount-in
    (token-a principal)
    (token-b principal)
    (amount-out uint)
  )
  (let (
      (pool-key (get-token-pair token-a token-b))
      (pool-data (map-get? pools pool-key))
    )
    (match pool-data
      pool (let (
          (is-token-a-in (is-eq token-a (get token-a pool-key)))
          (reserve-in (if is-token-a-in
            (get reserve-a pool)
            (get reserve-b pool)
          ))
          (reserve-out (if is-token-a-in
            (get reserve-b pool)
            (get reserve-a pool)
          ))
          (numerator (* reserve-in amount-out))
          (denominator (- reserve-out amount-out))
          (amount-in-before-fee (/ numerator denominator))
          (amount-in-with-fee (/ (* amount-in-before-fee fee-denominator)
            (- fee-denominator fee-rate)
          ))
        )
        (if (and
            (> reserve-in u0)
            (> reserve-out amount-out)
            (> amount-out u0)
          )
          (some amount-in-with-fee)
          none
        )
      )
      none
    )
  )
)

;; Get pending rewards for a user
(define-read-only (get-pending-rewards
    (token-a principal)
    (token-b principal)
    (provider principal)
  )
  (let ((pool-key (get-token-pair token-a token-b)))
    (calculate-pending-rewards pool-key provider)
  )
)

;; Get total number of pools
(define-read-only (get-total-pools)
  (var-get total-pools)
)

;; Get current reward rate
(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

;; Get LP token balance for a user
(define-read-only (get-lp-balance (user principal))
  (ft-get-balance lp-token user)
)

;; Get total LP token supply
(define-read-only (get-total-lp-supply)
  (ft-get-supply lp-token)
)

;; Calculate liquidity amounts needed for adding liquidity
(define-read-only (calculate-liquidity-amounts
    (token-a principal)
    (token-b principal)
    (amount-a-desired uint)
    (amount-b-desired uint)
  )
  (let (
      (pool-key (get-token-pair token-a token-b))
      (pool-data (map-get? pools pool-key))
    )
    (match pool-data
      pool (let (
          (reserve-a (get reserve-a pool))
          (reserve-b (get reserve-b pool))
        )
        (if (and (is-eq reserve-a u0) (is-eq reserve-b u0))
          ;; First liquidity provision
          (some {
            amount-a: amount-a-desired,
            amount-b: amount-b-desired,
          })
          ;; Calculate optimal amounts
          (let (
              (amount-b-optimal (/ (* amount-a-desired reserve-b) reserve-a))
              (amount-a-optimal (/ (* amount-b-desired reserve-a) reserve-b))
            )
            (if (<= amount-b-optimal amount-b-desired)
              (some {
                amount-a: amount-a-desired,
                amount-b: amount-b-optimal,
              })
              (some {
                amount-a: amount-a-optimal,
                amount-b: amount-b-desired,
              })
            )
          )
        )
      )
      none
    )
  )
)
