;; Provider Verification Contract
;; This contract validates healthcare entities on the blockchain

(define-data-var admin principal tx-sender)

;; Map to store verified providers
(define-map verified-providers principal
  {
    name: (string-utf8 100),
    license-number: (string-utf8 50),
    specialty: (string-utf8 50),
    verified: bool,
    verification-date: uint
  }
)

;; Public function to register a provider (only admin can verify)
(define-public (register-provider (name (string-utf8 100)) (license-number (string-utf8 50)) (specialty (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set verified-providers tx-sender
      {
        name: name,
        license-number: license-number,
        specialty: specialty,
        verified: false,
        verification-date: u0
      }
    ))
  )
)

;; Public function to verify a provider
(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-providers provider)) (err u404))
    (ok (map-set verified-providers provider
      (merge (unwrap-panic (map-get? verified-providers provider))
        {
          verified: true,
          verification-date: block-height
        }
      )
    ))
  )
)

;; Read-only function to check if a provider is verified
(define-read-only (is-verified-provider (provider principal))
  (match (map-get? verified-providers provider)
    provider-data (ok (get verified provider-data))
    (err u404)
  )
)

;; Read-only function to get provider details
(define-read-only (get-provider-details (provider principal))
  (map-get? verified-providers provider)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
