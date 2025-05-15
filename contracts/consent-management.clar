;; Consent Management Contract
;; Controls permissions for data sharing

(define-data-var admin principal tx-sender)

;; Map to store patient consent records
(define-map consent-records
  { patient: principal, data-type: (string-utf8 50), provider: principal }
  {
    granted: bool,
    purpose: (string-utf8 100),
    expiration: uint,
    granted-at: uint
  }
)

;; Public function to grant consent
(define-public (grant-consent
  (data-type (string-utf8 50))
  (provider principal)
  (purpose (string-utf8 100))
  (expiration uint))
  (begin
    (ok (map-set consent-records
      { patient: tx-sender, data-type: data-type, provider: provider }
      {
        granted: true,
        purpose: purpose,
        expiration: expiration,
        granted-at: block-height
      }
    ))
  )
)

;; Public function to revoke consent
(define-public (revoke-consent (data-type (string-utf8 50)) (provider principal))
  (begin
    (asserts! (is-some (map-get? consent-records { patient: tx-sender, data-type: data-type, provider: provider })) (err u404))
    (ok (map-set consent-records
      { patient: tx-sender, data-type: data-type, provider: provider }
      (merge (unwrap-panic (map-get? consent-records { patient: tx-sender, data-type: data-type, provider: provider }))
        { granted: false }
      )
    ))
  )
)

;; Read-only function to check if consent is granted
(define-read-only (is-consent-granted (patient principal) (data-type (string-utf8 50)) (provider principal))
  (match (map-get? consent-records { patient: patient, data-type: data-type, provider: provider })
    consent-data (and
                   (get granted consent-data)
                   (< block-height (get expiration consent-data)))
    false
  )
)

;; Read-only function to get consent details
(define-read-only (get-consent-details (patient principal) (data-type (string-utf8 50)) (provider principal))
  (map-get? consent-records { patient: patient, data-type: data-type, provider: provider })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
