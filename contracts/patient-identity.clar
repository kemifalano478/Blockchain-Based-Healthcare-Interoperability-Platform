;; Patient Identity Contract
;; Securely manages patient information on the blockchain

(define-data-var admin principal tx-sender)

;; Map to store patient identities
;; The patient's identity is stored with a hash of their personal information
;; Only the hash is stored on-chain for privacy
(define-map patient-identities principal
  {
    identity-hash: (buff 32),
    created-at: uint,
    updated-at: uint
  }
)

;; Map to store authorized providers for each patient
(define-map patient-providers
  { patient: principal, provider: principal }
  { authorized: bool, authorized-at: uint }
)

;; Public function to register a patient identity
(define-public (register-patient (identity-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? patient-identities tx-sender)) (err u409))
    (ok (map-set patient-identities tx-sender
      {
        identity-hash: identity-hash,
        created-at: block-height,
        updated-at: block-height
      }
    ))
  )
)

;; Public function to update a patient identity
(define-public (update-patient (identity-hash (buff 32)))
  (begin
    (asserts! (is-some (map-get? patient-identities tx-sender)) (err u404))
    (ok (map-set patient-identities tx-sender
      (merge (unwrap-panic (map-get? patient-identities tx-sender))
        {
          identity-hash: identity-hash,
          updated-at: block-height
        }
      )
    ))
  )
)

;; Public function to authorize a provider
(define-public (authorize-provider (provider principal))
  (begin
    (asserts! (is-some (map-get? patient-identities tx-sender)) (err u404))
    (ok (map-set patient-providers
      { patient: tx-sender, provider: provider }
      { authorized: true, authorized-at: block-height }
    ))
  )
)

;; Public function to revoke provider authorization
(define-public (revoke-provider (provider principal))
  (begin
    (asserts! (is-some (map-get? patient-identities tx-sender)) (err u404))
    (ok (map-set patient-providers
      { patient: tx-sender, provider: provider }
      { authorized: false, authorized-at: block-height }
    ))
  )
)

;; Read-only function to check if a provider is authorized
(define-read-only (is-provider-authorized (patient principal) (provider principal))
  (match (map-get? patient-providers { patient: patient, provider: provider })
    auth-data (get authorized auth-data)
    false
  )
)

;; Read-only function to get patient identity hash
(define-read-only (get-patient-identity (patient principal))
  (map-get? patient-identities patient)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
