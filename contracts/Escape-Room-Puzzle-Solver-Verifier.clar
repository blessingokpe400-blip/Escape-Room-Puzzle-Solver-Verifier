(define-non-fungible-token escape-room-nft uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-solution (err u104))
(define-constant err-puzzle-inactive (err u105))
(define-constant err-already-solved (err u106))
(define-constant err-time-expired (err u107))
(define-constant err-min-difficulty (err u108))
(define-constant err-max-solvers-reached (err u109))
(define-constant err-hint-not-found (err u110))
(define-constant err-insufficient-payment (err u111))
(define-constant err-max-hints-reached (err u112))
(define-constant err-invalid-rating (err u113))
(define-constant err-not-solver (err u114))
(define-constant err-already-rated (err u115))

(define-data-var next-puzzle-id uint u1)
(define-data-var next-nft-id uint u1)
(define-data-var total-puzzles-created uint u0)
(define-data-var total-solutions-verified uint u0)

(define-map puzzles uint {
  creator: principal,
  title: (string-ascii 100),
  description: (string-ascii 500),
  solution-hash: (buff 32),
  difficulty: uint,
  reward-amount: uint,
  max-solvers: uint,
  current-solvers: uint,
  created-at: uint,
  expires-at: uint,
  active: bool
})

(define-map puzzle-solutions { puzzle-id: uint, solver: principal } {
  solved-at: uint,
  nft-id: uint,
  solution: (string-ascii 200)
})

(define-map user-stats principal {
  puzzles-solved: uint,
  nfts-earned: uint,
  total-rewards: uint,
  first-solve: uint,
  last-solve: uint
})

(define-map puzzle-leaderboard uint (list 50 principal))

(define-map puzzle-hints { puzzle-id: uint, hint-level: uint } {
  hint-text: (string-ascii 300),
  cost: uint,
  unlock-threshold: uint
})

(define-map user-hints-purchased { puzzle-id: uint, user: principal } {
  hints-used: (list 10 uint),
  total-spent: uint
})

(define-map user-created-puzzles principal (list 101 uint))

(define-map user-solved-puzzles principal (list 101 uint))

(define-map puzzle-ratings { puzzle-id: uint, rater: principal } {
  rating: uint,
  rated-at: uint
})

(define-map puzzle-rating-stats uint {
  total-ratings: uint,
  sum-ratings: uint,
  average-rating: uint
})

(define-public (create-puzzle 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (solution-hash (buff 32))
  (difficulty uint)
  (reward-amount uint)
  (max-solvers uint)
  (duration uint))
  (let 
    ((puzzle-id (var-get next-puzzle-id))
     (current-block burn-block-height)
     (created-list (default-to (list) (map-get? user-created-puzzles tx-sender))))
    (asserts! (>= difficulty u1) err-min-difficulty)
    (asserts! (<= difficulty u10) err-min-difficulty)
    (asserts! (> max-solvers u0) err-max-solvers-reached)
    (asserts! (> duration u0) err-time-expired)
    (map-set puzzles puzzle-id {
      creator: tx-sender,
      title: title,
      description: description,
      solution-hash: solution-hash,
      difficulty: difficulty,
      reward-amount: reward-amount,
      max-solvers: max-solvers,
      current-solvers: u0,
      created-at: current-block,
      expires-at: (+ current-block duration),
      active: true
    })
    (map-set puzzle-leaderboard puzzle-id (list))
    (map-set user-created-puzzles tx-sender (unwrap! (as-max-len? (append created-list puzzle-id) u101) err-max-hints-reached))
    (var-set next-puzzle-id (+ puzzle-id u1))
    (var-set total-puzzles-created (+ (var-get total-puzzles-created) u1))
    (ok puzzle-id)))

(define-public (add-puzzle-hint
  (puzzle-id uint)
  (hint-level uint)
  (hint-text (string-ascii 300))
  (cost uint)
  (unlock-threshold uint))
  (let
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) err-not-found)))
    (asserts! (is-eq tx-sender (get creator puzzle-info)) err-unauthorized)
    (asserts! (<= hint-level u5) err-max-hints-reached)
    (asserts! (> hint-level u0) err-hint-not-found)
    (map-set puzzle-hints { puzzle-id: puzzle-id, hint-level: hint-level } {
      hint-text: hint-text,
      cost: cost,
      unlock-threshold: unlock-threshold
    })
    (ok true)))

(define-public (purchase-hint
  (puzzle-id uint)
  (hint-level uint))
  (let
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) err-not-found))
     (hint-info (unwrap! (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: hint-level }) err-hint-not-found))
     (user-hint-data (default-to { hints-used: (list), total-spent: u0 } 
       (map-get? user-hints-purchased { puzzle-id: puzzle-id, user: tx-sender })))
     (current-solvers (get current-solvers puzzle-info)))
    (asserts! (get active puzzle-info) err-puzzle-inactive)
    (asserts! (>= current-solvers (get unlock-threshold hint-info)) err-hint-not-found)
    (asserts! (is-none (index-of (get hints-used user-hint-data) hint-level)) err-already-exists)
    (try! (stx-transfer? (get cost hint-info) tx-sender (get creator puzzle-info)))
    (map-set user-hints-purchased { puzzle-id: puzzle-id, user: tx-sender } {
      hints-used: (unwrap! (as-max-len? (append (get hints-used user-hint-data) hint-level) u10) err-max-hints-reached),
      total-spent: (+ (get total-spent user-hint-data) (get cost hint-info))
    })
    (ok (get hint-text hint-info))))

(define-public (solve-puzzle 
  (puzzle-id uint)
  (solution (string-ascii 200)))
  (let 
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) err-not-found))
     (solution-hash (sha256 (unwrap-panic (to-consensus-buff? solution))))
     (current-block burn-block-height)
     (nft-id (var-get next-nft-id))
     (solved-list (default-to (list) (map-get? user-solved-puzzles tx-sender))))
    (asserts! (get active puzzle-info) err-puzzle-inactive)
    (asserts! (< current-block (get expires-at puzzle-info)) err-time-expired)
    (asserts! (< (get current-solvers puzzle-info) (get max-solvers puzzle-info)) err-max-solvers-reached)
    (asserts! (is-eq solution-hash (get solution-hash puzzle-info)) err-invalid-solution)
    (asserts! (is-none (map-get? puzzle-solutions { puzzle-id: puzzle-id, solver: tx-sender })) err-already-solved)
    (try! (nft-mint? escape-room-nft nft-id tx-sender))
    (map-set puzzle-solutions { puzzle-id: puzzle-id, solver: tx-sender } {
      solved-at: current-block,
      nft-id: nft-id,
      solution: solution
    })
    (map-set user-solved-puzzles tx-sender (unwrap! (as-max-len? (append solved-list puzzle-id) u101) err-max-hints-reached))
    (map-set puzzles puzzle-id 
      (merge puzzle-info { current-solvers: (+ (get current-solvers puzzle-info) u1) }))
    (update-user-stats tx-sender (get reward-amount puzzle-info) current-block)
    (update-leaderboard puzzle-id tx-sender)
    (var-set next-nft-id (+ nft-id u1))
    (var-set total-solutions-verified (+ (var-get total-solutions-verified) u1))
    (ok nft-id)))

(define-public (deactivate-puzzle (puzzle-id uint))
  (let 
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) err-not-found)))
    (asserts! (or (is-eq tx-sender (get creator puzzle-info)) (is-eq tx-sender contract-owner)) err-unauthorized)
    (map-set puzzles puzzle-id (merge puzzle-info { active: false }))
    (ok true)))

(define-public (extend-puzzle-duration 
  (puzzle-id uint)
  (additional-duration uint))
  (let 
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) err-not-found)))
    (asserts! (is-eq tx-sender (get creator puzzle-info)) err-unauthorized)
    (asserts! (get active puzzle-info) err-puzzle-inactive)
    (map-set puzzles puzzle-id 
      (merge puzzle-info { expires-at: (+ (get expires-at puzzle-info) additional-duration) }))
    (ok true)))

(define-public (transfer-nft 
  (nft-id uint)
  (sender principal)
  (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-unauthorized)
    (nft-transfer? escape-room-nft nft-id sender recipient)))

(define-public (rate-puzzle
  (puzzle-id uint)
  (rating uint))
  (let
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) err-not-found))
     (current-stats (default-to { total-ratings: u0, sum-ratings: u0, average-rating: u0 }
       (map-get? puzzle-rating-stats puzzle-id)))
     (new-total (+ (get total-ratings current-stats) u1))
     (new-sum (+ (get sum-ratings current-stats) rating)))
    (asserts! (>= rating u1) err-invalid-rating)
    (asserts! (<= rating u5) err-invalid-rating)
    (asserts! (is-some (map-get? puzzle-solutions { puzzle-id: puzzle-id, solver: tx-sender })) err-not-solver)
    (asserts! (is-none (map-get? puzzle-ratings { puzzle-id: puzzle-id, rater: tx-sender })) err-already-rated)
    (map-set puzzle-ratings { puzzle-id: puzzle-id, rater: tx-sender } {
      rating: rating,
      rated-at: burn-block-height
    })
    (map-set puzzle-rating-stats puzzle-id {
      total-ratings: new-total,
      sum-ratings: new-sum,
      average-rating: (/ new-sum new-total)
    })
    (ok true)))

(define-private (update-user-stats 
  (user principal)
  (reward uint)
  (block-time uint))
  (let 
    ((current-stats (default-to 
      { puzzles-solved: u0, nfts-earned: u0, total-rewards: u0, first-solve: u0, last-solve: u0 }
      (map-get? user-stats user))))
    (map-set user-stats user {
      puzzles-solved: (+ (get puzzles-solved current-stats) u1),
      nfts-earned: (+ (get nfts-earned current-stats) u1),
      total-rewards: (+ (get total-rewards current-stats) reward),
      first-solve: (if (is-eq (get first-solve current-stats) u0) block-time (get first-solve current-stats)),
      last-solve: block-time
    })
    true))

(define-private (update-leaderboard 
  (puzzle-id uint)
  (solver principal))
  (let 
    ((current-leaderboard (default-to (list) (map-get? puzzle-leaderboard puzzle-id))))
    (map-set puzzle-leaderboard puzzle-id (unwrap! (as-max-len? (append current-leaderboard solver) u50) false))
    true))

(define-read-only (get-puzzle (puzzle-id uint))
  (map-get? puzzles puzzle-id))

(define-read-only (get-puzzle-solution 
  (puzzle-id uint)
  (solver principal))
  (map-get? puzzle-solutions { puzzle-id: puzzle-id, solver: solver }))

(define-read-only (get-user-stats (user principal))
  (map-get? user-stats user))

(define-read-only (get-user-created-puzzles (user principal))
  (map-get? user-created-puzzles user))

(define-read-only (get-user-solved-puzzles (user principal))
  (map-get? user-solved-puzzles user))

(define-read-only (get-puzzle-leaderboard (puzzle-id uint))
  (map-get? puzzle-leaderboard puzzle-id))

(define-read-only (get-nft-owner (nft-id uint))
  (nft-get-owner? escape-room-nft nft-id))

(define-read-only (get-contract-stats)
  {
    total-puzzles: (var-get total-puzzles-created),
    total-solutions: (var-get total-solutions-verified),
    next-puzzle-id: (var-get next-puzzle-id),
    next-nft-id: (var-get next-nft-id)
  })

(define-read-only (is-puzzle-active (puzzle-id uint))
  (match (map-get? puzzles puzzle-id)
    puzzle-info (and 
      (get active puzzle-info)
      (< burn-block-height (get expires-at puzzle-info))
      (< (get current-solvers puzzle-info) (get max-solvers puzzle-info)))
    false))

(define-read-only (get-active-puzzles-count)
  (fold check-active-puzzle 
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
    u0))

(define-private (check-active-puzzle (puzzle-id uint) (count uint))
  (if (is-puzzle-active puzzle-id)
    (+ count u1)
    count))

(define-read-only (has-solved-puzzle 
  (puzzle-id uint)
  (solver principal))
  (is-some (map-get? puzzle-solutions { puzzle-id: puzzle-id, solver: solver })))

(define-read-only (get-puzzle-progress (puzzle-id uint))
  (match (map-get? puzzles puzzle-id)
    puzzle-info (some {
      current-solvers: (get current-solvers puzzle-info),
      max-solvers: (get max-solvers puzzle-info),
      progress-percentage: (/ (* (get current-solvers puzzle-info) u100) (get max-solvers puzzle-info))
    })
    none))

(define-read-only (get-puzzle-hint
  (puzzle-id uint)
  (hint-level uint))
  (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: hint-level }))

(define-read-only (get-user-purchased-hints
  (puzzle-id uint)
  (user principal))
  (map-get? user-hints-purchased { puzzle-id: puzzle-id, user: user }))

(define-read-only (can-access-hint
  (puzzle-id uint)
  (hint-level uint)
  (user principal))
  (match (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: hint-level })
    hint-info
      (match (map-get? puzzles puzzle-id)
        puzzle-info
          (and
            (>= (get current-solvers puzzle-info) (get unlock-threshold hint-info))
            (match (map-get? user-hints-purchased { puzzle-id: puzzle-id, user: user })
              user-hints (is-some (index-of (get hints-used user-hints) hint-level))
              false))
        false)
    false))

(define-read-only (get-available-hints
  (puzzle-id uint)
  (user principal))
  (let
    ((puzzle-info (unwrap! (map-get? puzzles puzzle-id) none))
     (current-solvers (get current-solvers puzzle-info)))
    (some {
      hint-1: (and 
        (is-some (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: u1 }))
        (>= current-solvers (get unlock-threshold (unwrap-panic (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: u1 }))))),
      hint-2: (and 
        (is-some (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: u2 }))
        (>= current-solvers (get unlock-threshold (unwrap-panic (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: u2 }))))),
      hint-3: (and 
        (is-some (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: u3 }))
        (>= current-solvers (get unlock-threshold (unwrap-panic (map-get? puzzle-hints { puzzle-id: puzzle-id, hint-level: u3 })))))
    })))

(define-read-only (get-puzzle-rating-stats (puzzle-id uint))
  (map-get? puzzle-rating-stats puzzle-id))

(define-read-only (get-user-puzzle-rating
  (puzzle-id uint)
  (user principal))
  (map-get? puzzle-ratings { puzzle-id: puzzle-id, rater: user }))

(define-read-only (has-rated-puzzle
  (puzzle-id uint)
  (user principal))
  (is-some (map-get? puzzle-ratings { puzzle-id: puzzle-id, rater: user })))
