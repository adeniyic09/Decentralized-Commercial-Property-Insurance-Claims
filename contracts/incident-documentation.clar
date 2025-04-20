;; Incident Documentation Contract
;; This contract records details of property damage incidents

;; Define data maps and variables
(define-data-var admin principal tx-sender)

(define-map incidents
  { incident-id: uint }
  {
    policy-id: uint,
    reporter: principal,
    incident-date: uint,
    description: (string-ascii 500),
    damage-estimate: uint,
    status: (string-ascii 20),
    location: (string-ascii 256)
  }
)

;; Create a new incident report
(define-public (report-incident
    (incident-id uint)
    (policy-id uint)
    (incident-date uint)
    (description (string-ascii 500))
    (damage-estimate uint)
    (location (string-ascii 256))
  )
  (begin
    (asserts! (is-none (map-get? incidents { incident-id: incident-id })) (err u1))
    (map-set incidents
      { incident-id: incident-id }
      {
        policy-id: policy-id,
        reporter: tx-sender,
        incident-date: incident-date,
        description: description,
        damage-estimate: damage-estimate,
        status: "reported",
        location: location
      }
    )
    (ok true)
  )
)

;; Update incident status
(define-public (update-incident-status
    (incident-id uint)
    (new-status (string-ascii 20))
  )
  (let (
    (incident (unwrap! (map-get? incidents { incident-id: incident-id }) (err u2)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (map-set incidents
      { incident-id: incident-id }
      (merge incident { status: new-status })
    )
    (ok true)
  )
)

;; Update damage estimate
(define-public (update-damage-estimate
    (incident-id uint)
    (new-estimate uint)
  )
  (let (
    (incident (unwrap! (map-get? incidents { incident-id: incident-id }) (err u2)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (map-set incidents
      { incident-id: incident-id }
      (merge incident { damage-estimate: new-estimate })
    )
    (ok true)
  )
)

;; Get incident details
(define-read-only (get-incident (incident-id uint))
  (map-get? incidents { incident-id: incident-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (var-set admin new-admin)
    (ok true)
  )
)
