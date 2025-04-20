;; Adjuster Assignment Contract
;; This contract manages the claim investigation process

;; Define data maps and variables
(define-data-var admin principal tx-sender)

(define-map adjusters
  { adjuster-id: uint }
  {
    address: principal,
    name: (string-ascii 100),
    is-active: bool,
    specialty: (string-ascii 50)
  }
)

(define-map assignments
  { incident-id: uint }
  {
    adjuster-id: uint,
    assigned-date: uint,
    status: (string-ascii 20),
    notes: (string-ascii 500)
  }
)

;; Register a new adjuster
(define-public (register-adjuster
    (adjuster-id uint)
    (name (string-ascii 100))
    (specialty (string-ascii 50))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (is-none (map-get? adjusters { adjuster-id: adjuster-id })) (err u2))
    (map-set adjusters
      { adjuster-id: adjuster-id }
      {
        address: tx-sender,
        name: name,
        is-active: true,
        specialty: specialty
      }
    )
    (ok true)
  )
)

;; Assign an adjuster to an incident
(define-public (assign-adjuster
    (incident-id uint)
    (adjuster-id uint)
    (notes (string-ascii 500))
  )
  (let (
    (adjuster (unwrap! (map-get? adjusters { adjuster-id: adjuster-id }) (err u3)))
    (current-time (unwrap! (get-block-info? time (- block-height u1)) (err u4)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (get is-active adjuster) (err u5))
    (asserts! (is-none (map-get? assignments { incident-id: incident-id })) (err u6))

    (map-set assignments
      { incident-id: incident-id }
      {
        adjuster-id: adjuster-id,
        assigned-date: current-time,
        status: "assigned",
        notes: notes
      }
    )
    (ok true)
  )
)

;; Update assignment status
(define-public (update-assignment-status
    (incident-id uint)
    (new-status (string-ascii 20))
    (notes (string-ascii 500))
  )
  (let (
    (assignment (unwrap! (map-get? assignments { incident-id: incident-id }) (err u7)))
    (adjuster (unwrap! (map-get? adjusters { adjuster-id: (get adjuster-id assignment) }) (err u3)))
  )
    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get address adjuster))) (err u8))

    (map-set assignments
      { incident-id: incident-id }
      (merge assignment {
        status: new-status,
        notes: notes
      })
    )
    (ok true)
  )
)

;; Get adjuster details
(define-read-only (get-adjuster (adjuster-id uint))
  (map-get? adjusters { adjuster-id: adjuster-id })
)

;; Get assignment details
(define-read-only (get-assignment (incident-id uint))
  (map-get? assignments { incident-id: incident-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
