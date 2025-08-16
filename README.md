# Network Infrastructure Sharing System

A comprehensive blockchain-based system for managing shared use of telecommunications infrastructure including cell towers and fiber optic networks.

## Overview

This system enables transparent pricing, capacity allocation, rural broadband expansion, infrastructure investment sharing, and quality of service monitoring through five interconnected Clarity smart contracts.

## Core Features

### Infrastructure Management
- **Infrastructure Registry**: Manages cell towers and fiber optic network registration
- **Capacity Allocation**: Handles dynamic capacity distribution and availability tracking
- **Transparent Pricing**: Implements fair pricing mechanisms based on usage and demand

### Investment & Collaboration
- **Investment Sharing**: Facilitates cost sharing for infrastructure development
- **Rural Expansion**: Supports broadband expansion initiatives in underserved areas
- **Quality Monitoring**: Tracks service quality and handles dispute resolution

## Smart Contracts

### 1. Infrastructure Registry (`infrastructure-registry.clar`)
- Register and manage cell towers and fiber networks
- Track infrastructure ownership and specifications
- Handle infrastructure status updates

### 2. Capacity Management (`capacity-management.clar`)
- Allocate network capacity to different providers
- Monitor real-time usage and availability
- Implement fair usage policies

### 3. Pricing System (`pricing-system.clar`)
- Calculate transparent pricing based on usage
- Handle dynamic pricing adjustments
- Manage payment processing and settlements

### 4. Investment Sharing (`investment-sharing.clar`)
- Coordinate infrastructure investment projects
- Track contributor shares and returns
- Manage funding milestones and distributions

### 5. Quality Monitoring (`quality-monitoring.clar`)
- Monitor service quality metrics
- Handle dispute resolution processes
- Track SLA compliance and penalties

## Key Benefits

- **Cost Reduction**: Shared infrastructure reduces individual operator costs
- **Rural Coverage**: Enables economically viable rural broadband expansion
- **Transparency**: Blockchain-based pricing and allocation ensures fairness
- **Quality Assurance**: Automated monitoring and dispute resolution
- **Investment Efficiency**: Coordinated infrastructure development

## Data Types

- **Infrastructure**: Cell towers and fiber networks with specifications
- **Capacity**: Available bandwidth and usage allocations
- **Pricing**: Dynamic pricing models and payment records
- **Investments**: Funding projects and contributor tracking
- **Quality Metrics**: Performance data and SLA compliance

## Usage Patterns

1. **Infrastructure Registration**: Operators register their infrastructure assets
2. **Capacity Allocation**: System allocates available capacity to requesting providers
3. **Usage Monitoring**: Real-time tracking of network usage and performance
4. **Payment Processing**: Automated billing based on actual usage
5. **Quality Assurance**: Continuous monitoring with dispute resolution

## Technical Architecture

Built on Stacks blockchain using Clarity smart contracts for:
- Immutable infrastructure records
- Transparent pricing mechanisms
- Automated capacity allocation
- Decentralized dispute resolution
- Trustless investment coordination

## Getting Started

1. Deploy the five smart contracts to Stacks blockchain
2. Register infrastructure assets through the registry
3. Configure capacity allocation policies
4. Set up pricing parameters
5. Begin monitoring and allocation processes

This system promotes efficient infrastructure sharing while maintaining competitive markets and ensuring quality service delivery.
\`\`\`

```clar file="contracts/infrastructure-registry.clar"
;; Infrastructure Registry Contract
;; Manages registration and tracking of cell towers and fiber optic networks

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
    created-at: uint,
    specifications: (string-ascii 500)
  }
)

(define-map owner-infrastructures
  { owner: principal, infrastructure-id: uint }
  { active: bool }
)

(define-map infrastructure-stats
  { infrastructure-type: (string-ascii 20) }
  { total-count: uint, active-count: uint }
)

;; Public Functions

;; Register new infrastructure
(define-public (register-infrastructure 
  (infrastructure-type (string-ascii 20))
  (location (string-ascii 100))
  (capacity uint)
  (specifications (string-ascii 500)))
  (let ((infrastructure-id (var-get next-infrastructure-id)))
    (asserts! (> capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len infrastructure-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    
    ;; Store infrastructure data
    (map-set infrastructures
      { id: infrastructure-id }
      {
        owner: tx-sender,
        infrastructure-type: infrastructure-type,
        location: location,
        capacity: capacity,
        status: "active",
        created-at: block-height,
        specifications: specifications
      }
    )
    
    ;; Track owner's infrastructure
    (map-set owner-infrastructures
      { owner: tx-sender, infrastructure-id: infrastructure-id }
      { active: true }
    )
    
    ;; Update statistics
    (update-infrastructure-stats infrastructure-type true)
    
    ;; Increment ID counter
    (var-set next-infrastructure-id (+ infrastructure-id u1))
    
    (ok infrastructure-id)
  )
)

;; Update infrastructure status
(define-public (update-infrastructure-status (infrastructure-id uint) (new-status (string-ascii 20)))
  (let ((infrastructure (unwrap! (map-get? infrastructures { id: infrastructure-id }) ERR-INFRASTRUCTURE-NOT-FOUND)))
    (asserts! (is-eq (get owner infrastructure) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)
    
    (map-set infrastructures
      { id: infrastructure-id }
      (merge infrastructure { status: new-status })
    )
    
    (ok true)
  )
)

;; Update infrastructure capacity
(define-public (update-infrastructure-capacity (infrastructure-id uint) (new-capacity uint))
  (let ((infrastructure (unwrap! (map-get? infrastructures { id: infrastructure-id }) ERR-INFRASTRUCTURE-NOT-FOUND)))
    (asserts! (is-eq (get owner infrastructure) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> new-capacity u0) ERR-INVALID-INPUT)
    
    (map-set infrastructures
      { id: infrastructure-id }
      (merge infrastructure { capacity: new-capacity })
    )
    
    (ok true)
  )
)

;; Deactivate infrastructure
(define-public (deactivate-infrastructure (infrastructure-id uint))
  (let ((infrastructure (unwrap! (map-get? infrastructures { id: infrastructure-id }) ERR-INFRASTRUCTURE-NOT-FOUND)))
    (asserts! (is-eq (get owner infrastructure) tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Update status to inactive
    (map-set infrastructures
      { id: infrastructure-id }
      (merge infrastructure { status: "inactive" })
    )
    
    ;; Update owner tracking
    (map-set owner-infrastructures
      { owner: tx-sender, infrastructure-id: infrastructure-id }
      { active: false }
    )
    
    ;; Update statistics
    (update-infrastructure-stats (get infrastructure-type infrastructure) false)
    
    (ok true)
  )
)

;; Read-only Functions

;; Get infrastructure details
(define-read-only (get-infrastructure (infrastructure-id uint))
  (map-get? infrastructures { id: infrastructure-id })
)

;; Get infrastructure statistics
(define-read-only (get-infrastructure-stats (infrastructure-type (string-ascii 20)))
  (map-get? infrastructure-stats { infrastructure-type: infrastructure-type })
)

;; Check if user owns infrastructure
(define-read-only (is-infrastructure-owner (owner principal) (infrastructure-id uint))
  (match (map-get? owner-infrastructures { owner: owner, infrastructure-id: infrastructure-id })
    entry (get active entry)
    false
  )
)

;; Get next infrastructure ID
(define-read-only (get-next-infrastructure-id)
  (var-get next-infrastructure-id)
)

;; Private Functions

;; Update infrastructure statistics
(define-private (update-infrastructure-stats (infrastructure-type (string-ascii 20)) (is-activation bool))
  (let ((current-stats (default-to { total-count: u0, active-count: u0 } 
                                  (map-get? infrastructure-stats { infrastructure-type: infrastructure-type }))))
    (if is-activation
      (map-set infrastructure-stats
        { infrastructure-type: infrastructure-type }
        {
          total-count: (+ (get total-count current-stats) u1),
          active-count: (+ (get active-count current-stats) u1)
        }
      )
      (map-set infrastructure-stats
        { infrastructure-type: infrastructure-type }
        {
          total-count: (get total-count current-stats),
          active-count: (if (> (get active-count current-stats) u0)
                          (- (get active-count current-stats) u1)
                          u0)
        }
      )
    )
  )
)
