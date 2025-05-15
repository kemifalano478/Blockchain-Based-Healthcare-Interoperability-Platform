;; Access Tracking Contract
;; Records who viewed patient information

(define-data-var admin principal tx-sender)

;; Map to store access records
(define-map access-records uint
  {
    patient: principal,
    provider: principal,
    data-type: (string-utf8 50),
    purpose: (string-utf8 100),
    timestamp: uint
  }
)

;; Counter for access record IDs
(define-data-var access-counter uint u0)

;; Public function to record data access
(define-public (record-access
  (patient principal)
  (data-type (string-utf8 50))
  (purpose (string-utf8 100)))
  (let
    (
      (current-counter (var-get access-counter))
      (next-counter (+ current-counter u1))
    )
    (begin
      ;; Check if consent is granted by calling the consent management contract
      ;; In a real implementation, this would use contract-call? to the consent-management contract
      ;; For simplicity, we're just recording the access here

      (var-set access-counter next-counter)
      (ok (map-set access-records current-counter
        {
          patient: patient,
          provider: tx-sender,
          data-type: data-type,
          purpose: purpose,
          timestamp: block-height
        }
      ))
    )
  )
)

;; Read-only function to get access record by ID
(define-read-only (get-access-record (record-id uint))
  (map-get? access-records record-id)
)

;; Read-only function to get the current access counter
(define-read-only (get-access-counter)
  (var-get access-counter)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
