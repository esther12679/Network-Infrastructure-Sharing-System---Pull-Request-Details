;; Infrastructure Registry Contract
;; Manages registration and tracking of network infrastructure assets

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INFRASTRUCTURE-EXISTS (err u101))
(define-constant ERR-INFRASTRUCTURE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-INPUT (err u103))

;; Data Variables
(define-data-var next-infrastructure-id uint u1)

;; Data Maps
(define-map infrastructures
  { id: uint }
  {
    owner: principal,
    infrastructure-type: (string-ascii 20),
    location: (string-ascii 100),
    capacity: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map owner-infrastructures
  { owner: principal, infrastructure-id: uint }
  { active: bool }
)

;; Public Functions
(define-public (register-infrastructure (infrastructure-type (string-ascii 20)) (location (string-ascii 100)) (capacity uint))
  (let
    (
      (infrastructure-id (var-get next-infrastructure-id))
    )
    (asserts! (> capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len infrastructure-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)

    (map-set infrastructures
      { id: infrastructure-id }
      {
        owner: tx-sender,
        infrastructure-type: infrastructure-type,
        location: location,
        capacity: capacity,
        status: "active",
        created-at: block-height
      }
    )

    (map-set owner-infrastructures
      { owner: tx-sender, infrastructure-id: infrastructure-id }
      { active: true }
    )

    (var-set next-infrastructure-id (+ infrastructure-id u1))
    (ok infrastructure-id)
  )
)

(define-public (update-infrastructure-status (infrastructure-id uint) (new-status (string-ascii 20)))
  (let
    (
      (infrastructure (unwrap! (map-get? infrastructures { id: infrastructure-id }) ERR-INFRASTRUCTURE-NOT-FOUND))
    )
    (asserts! (is-eq (get owner infrastructure) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (map-set infrastructures
      { id: infrastructure-id }
      (merge infrastructure { status: new-status })
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-infrastructure (infrastructure-id uint))
  (map-get? infrastructures { id: infrastructure-id })
)

(define-read-only (get-next-infrastructure-id)
  (var-get next-infrastructure-id)
)

(define-read-only (is-infrastructure-owner (infrastructure-id uint) (owner principal))
  (match (map-get? infrastructures { id: infrastructure-id })
    infrastructure (is-eq (get owner infrastructure) owner)
    false
  )
)
