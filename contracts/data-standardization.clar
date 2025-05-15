;; Data Standardization Contract
;; Normalizes medical information formats

(define-data-var admin principal tx-sender)

;; Map to store supported data formats
(define-map data-formats (string-utf8 50)
  {
    format-version: (string-utf8 20),
    is-supported: bool,
    added-at: uint
  }
)

;; Map to store data transformation rules
(define-map transformation-rules
  { from-format: (string-utf8 50), to-format: (string-utf8 50) }
  { rule-hash: (buff 32), created-at: uint }
)

;; Public function to add a supported data format
(define-public (add-data-format (format-name (string-utf8 50)) (format-version (string-utf8 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set data-formats format-name
      {
        format-version: format-version,
        is-supported: true,
        added-at: block-height
      }
    ))
  )
)

;; Public function to deprecate a data format
(define-public (deprecate-data-format (format-name (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? data-formats format-name)) (err u404))
    (ok (map-set data-formats format-name
      (merge (unwrap-panic (map-get? data-formats format-name))
        { is-supported: false }
      )
    ))
  )
)

;; Public function to add a transformation rule
(define-public (add-transformation-rule
  (from-format (string-utf8 50))
  (to-format (string-utf8 50))
  (rule-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? data-formats from-format)) (err u404))
    (asserts! (is-some (map-get? data-formats to-format)) (err u404))
    (ok (map-set transformation-rules
      { from-format: from-format, to-format: to-format }
      { rule-hash: rule-hash, created-at: block-height }
    ))
  )
)

;; Read-only function to check if a format is supported
(define-read-only (is-format-supported (format-name (string-utf8 50)))
  (match (map-get? data-formats format-name)
    format-data (get is-supported format-data)
    false
  )
)

;; Read-only function to get transformation rule
(define-read-only (get-transformation-rule (from-format (string-utf8 50)) (to-format (string-utf8 50)))
  (map-get? transformation-rules { from-format: from-format, to-format: to-format })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
