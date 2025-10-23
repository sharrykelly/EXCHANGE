;;
;; Mock SIP-010 Token B - Test Token for DEX Testing
;;
;; This is a simple SIP-010 compliant fungible token used for testing
;; the decentralized exchange contract. It implements all required
;; SIP-010 trait functions plus a mint function for easy test setup.
;;
;; Symbol: TKB
;; Name: Token B
;; Decimals: 6
;;

;; Define the SIP-010 trait locally (trait functions required for compliance)
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; Define the fungible token
(define-fungible-token token-b)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))

;; ============================================
;; SIP-010 STANDARD FUNCTIONS
;; ============================================

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (try! (ft-transfer? token-b amount sender recipient))
        (match memo to-print (print to-print) 0x)
        (ok true)
    )
)

(define-read-only (get-name)
    (ok "Token B")
)

(define-read-only (get-symbol)
    (ok "TKB")
)

(define-read-only (get-decimals)
    (ok u6)
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance token-b who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply token-b))
)

(define-read-only (get-token-uri)
    (ok none)
)

;; ============================================
;; TEST HELPER FUNCTIONS
;; ============================================

;; Mint tokens to a recipient (owner only - for test setup)
(define-public (mint (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ft-mint? token-b amount recipient)
    )
)
