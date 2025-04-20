;; Policy Verification Contract
;; This contract validates coverage terms and conditions for property insurance policies

;; Define data maps and variables
(define-data-var admin principal tx-sender)

(define-map policies
  { policy-id: uint }
  {
    owner: principal,
    coverage-amount: uint,
    deductible: uint,
    start-date: uint,
    end-date: uint,
    property-address: (string-ascii 256),
    is-active: bool
  }
)

;; Create a new insurance policy
(define-public (create-policy
    (policy-id uint)
    (coverage-amount uint)
    (deductible uint)
    (start-date uint)
    (end-date uint)
    (property-address (string-ascii 256))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (> end-date start-date) (err u2))
    (asserts! (> coverage-amount u0) (err u3))
    (asserts! (is-none (map-get? policies { policy-id: policy-id })) (err u4))
    (map-set policies
      { policy-id: policy-id }
      {
        owner: tx-sender,
        coverage-amount: coverage-amount,
        deductible: deductible,
        start-date: start-date,
        end-date: end-date,
        property-address: property-address,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Verify if a policy is active and valid
(define-public (verify-policy (policy-id uint))
  (let (
    (policy (unwrap! (map-get? policies { policy-id: policy-id }) (err u5)))
    (current-time (unwrap! (get-block-info? time (- block-height u1)) (err u6)))
  )
    (if (and
          (get is-active policy)
          (>= current-time (get start-date policy))
          (<= current-time (get end-date policy))
        )
      (ok true)
      (err u7)
    )
  )
)

;; Update policy status (activate/deactivate)
(define-public (update-policy-status (policy-id uint) (is-active bool))
  (let (
    (policy (unwrap! (map-get? policies { policy-id: policy-id }) (err u5)))
  )
    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get owner policy))) (err u8))
    (map-set policies
      { policy-id: policy-id }
      (merge policy { is-active: is-active })
    )
    (ok true)
  )
)

;; Get policy details
(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
