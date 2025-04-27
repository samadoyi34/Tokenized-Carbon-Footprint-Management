;; Entity Verification Contract
;; Validates business identities for carbon footprint tracking

(define-data-var admin principal tx-sender)

;; Entity status: 0 = unverified, 1 = pending, 2 = verified, 3 = rejected
(define-map entities principal
  {
    name: (string-utf8 100),
    industry: (string-utf8 50),
    status: uint,
    verification-date: uint
  }
)

(define-read-only (get-entity (entity-id principal))
  (default-to
    {
      name: u"",
      industry: u"",
      status: u0,
      verification-date: u0
    }
    (map-get? entities entity-id)
  )
)

(define-public (register-entity (name (string-utf8 100)) (industry (string-utf8 50)))
  (begin
    (asserts! (is-none (map-get? entities tx-sender)) (err u1)) ;; Entity already exists
    (map-set entities tx-sender
      {
        name: name,
        industry: industry,
        status: u1, ;; pending
        verification-date: u0
      }
    )
    (ok true)
  )
)

(define-public (verify-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (asserts! (is-some (map-get? entities entity-id)) (err u3)) ;; Entity doesn't exist
    (map-set entities entity-id
      (merge (unwrap-panic (map-get? entities entity-id))
        {
          status: u2, ;; verified
          verification-date: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (reject-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (asserts! (is-some (map-get? entities entity-id)) (err u3)) ;; Entity doesn't exist
    (map-set entities entity-id
      (merge (unwrap-panic (map-get? entities entity-id))
        {
          status: u3, ;; rejected
          verification-date: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (var-set admin new-admin)
    (ok true)
  )
)
