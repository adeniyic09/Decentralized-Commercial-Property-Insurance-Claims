;; Contractor Verification Contract
;; This contract validates qualified repair providers

;; Define data maps and variables
(define-data-var admin principal tx-sender)

(define-map contractors
  { contractor-id: uint }
  {
    address: principal,
    name: (string-ascii 100),
    specialty: (string-ascii 50),
    license-number: (string-ascii 50),
    is-verified: bool,
    rating: uint
  }
)

(define-map repair-jobs
  { job-id: uint }
  {
    incident-id: uint,
    contractor-id: uint,
    estimate-amount: uint,
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20)
  }
)

;; Register a new contractor
(define-public (register-contractor
    (contractor-id uint)
    (name (string-ascii 100))
    (specialty (string-ascii 50))
    (license-number (string-ascii 50))
  )
  (begin
    (asserts! (is-none (map-get? contractors { contractor-id: contractor-id })) (err u1))
    (map-set contractors
      { contractor-id: contractor-id }
      {
        address: tx-sender,
        name: name,
        specialty: specialty,
        license-number: license-number,
        is-verified: false,
        rating: u0
      }
    )
    (ok true)
  )
)

;; Verify a contractor
(define-public (verify-contractor
    (contractor-id uint)
    (is-verified bool)
  )
  (let (
    (contractor (unwrap! (map-get? contractors { contractor-id: contractor-id }) (err u2)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor { is-verified: is-verified })
    )
    (ok true)
  )
)

;; Create a repair job
(define-public (create-repair-job
    (job-id uint)
    (incident-id uint)
    (contractor-id uint)
    (estimate-amount uint)
    (start-date uint)
    (end-date uint)
  )
  (let (
    (contractor (unwrap! (map-get? contractors { contractor-id: contractor-id }) (err u2)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (asserts! (get is-verified contractor) (err u4))
    (asserts! (> end-date start-date) (err u5))
    (asserts! (is-none (map-get? repair-jobs { job-id: job-id })) (err u6))

    (map-set repair-jobs
      { job-id: job-id }
      {
        incident-id: incident-id,
        contractor-id: contractor-id,
        estimate-amount: estimate-amount,
        start-date: start-date,
        end-date: end-date,
        status: "scheduled"
      }
    )
    (ok true)
  )
)

;; Update repair job status
(define-public (update-job-status
    (job-id uint)
    (new-status (string-ascii 20))
  )
  (let (
    (job (unwrap! (map-get? repair-jobs { job-id: job-id }) (err u7)))
    (contractor (unwrap! (map-get? contractors { contractor-id: (get contractor-id job) }) (err u2)))
  )
    (asserts! (or
      (is-eq tx-sender (var-get admin))
      (is-eq tx-sender (get address contractor))
    ) (err u3))

    (map-set repair-jobs
      { job-id: job-id }
      (merge job { status: new-status })
    )
    (ok true)
  )
)

;; Rate a contractor
(define-public (rate-contractor
    (contractor-id uint)
    (rating uint)
  )
  (let (
    (contractor (unwrap! (map-get? contractors { contractor-id: contractor-id }) (err u2)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (asserts! (<= rating u5) (err u8))

    (map-set contractors
      { contractor-id: contractor-id }
      (merge contractor { rating: rating })
    )
    (ok true)
  )
)

;; Get contractor details
(define-read-only (get-contractor (contractor-id uint))
  (map-get? contractors { contractor-id: contractor-id })
)

;; Get repair job details
(define-read-only (get-repair-job (job-id uint))
  (map-get? repair-jobs { job-id: job-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (var-set admin new-admin)
    (ok true)
  )
)
