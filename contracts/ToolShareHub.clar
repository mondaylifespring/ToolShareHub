;; ToolShareHub: Community Tool Lending Library
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-TOOL-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-LISTED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-DAYS (err u5))
(define-constant ERR-INVALID-CATEGORY (err u6))
(define-constant ERR-INVALID-CONDITION (err u7))
(define-constant ERR-INVALID-NAME (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))
(define-constant ERR-REQUEST-NOT-FOUND (err u10))
(define-constant ERR-SELF-BORROW (err u11))
(define-constant ERR-TOOL-UNAVAILABLE (err u12))
(define-constant ERR-REQUEST-INVALID-STATUS (err u13))
(define-constant MIN-DAYS u1)

(define-data-var next-tool-id uint u1)
(define-data-var next-request-id uint u1)

(define-map tools
    uint
    {
        owner: principal,
        tool-name: (string-utf8 50),
        description: (string-utf8 200),
        category: (string-utf8 15),
        condition: (string-utf8 20),
        status: (string-utf8 15),
        max-lending-days: uint
    }
)

(define-map borrow-requests
    uint
    {
        borrower: principal,
        owner: principal,
        tool-id: uint,
        duration-days: uint,
        status: (string-utf8 15)
    }
)

(define-private (validate-category (category (string-utf8 15)))
    (or 
        (is-eq category u"Power-Tools")
        (is-eq category u"Hand-Tools")
        (is-eq category u"Garden-Tools")
        (is-eq category u"Kitchen-Tools")
        (is-eq category u"Automotive")
        (is-eq category u"Electronics")
    )
)

(define-private (validate-condition (condition (string-utf8 20)))
    (or 
        (is-eq condition u"Excellent")
        (is-eq condition u"Good")
        (is-eq condition u"Fair")
        (is-eq condition u"Needs-Repair")
        (is-eq condition u"For-Parts")
    )
)

(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)

(define-public (add-tool 
    (tool-name (string-utf8 50))
    (description (string-utf8 200))
    (category (string-utf8 15))
    (condition (string-utf8 20))
    (max-lending-days uint)
)
    (let
        (
            (tool-id (var-get next-tool-id))
        )
        (asserts! (validate-text-length tool-name u3 u50) ERR-INVALID-NAME)
        (asserts! (validate-text-length description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= max-lending-days MIN-DAYS) ERR-INVALID-DAYS)
        (asserts! (validate-category category) ERR-INVALID-CATEGORY)
        (asserts! (validate-condition condition) ERR-INVALID-CONDITION)
        
        (map-set tools tool-id {
            owner: tx-sender,
            tool-name: tool-name,
            description: description,
            category: category,
            condition: condition,
            status: u"available",
            max-lending-days: max-lending-days
        })
        (var-set next-tool-id (+ tool-id u1))
        (ok tool-id)
    )
)

(define-public (remove-tool (tool-id uint))
    (let
        (
            (tool (unwrap! (map-get? tools tool-id) ERR-TOOL-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get owner tool)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status tool) u"available") ERR-INVALID-STATUS)
        (ok (map-set tools tool-id (merge tool { status: u"removed" })))
    )
)

(define-public (request-borrow (tool-id uint) (duration-days uint))
    (let
        (
            (tool (unwrap! (map-get? tools tool-id) ERR-TOOL-NOT-FOUND))
            (request-id (var-get next-request-id))
        )
        (asserts! (is-eq (get status tool) u"available") ERR-TOOL-UNAVAILABLE)
        (asserts! (not (is-eq tx-sender (get owner tool))) ERR-SELF-BORROW)
        (asserts! (<= duration-days (get max-lending-days tool)) ERR-INVALID-DAYS)
        
        (map-set borrow-requests request-id {
            borrower: tx-sender,
            owner: (get owner tool),
            tool-id: tool-id,
            duration-days: duration-days,
            status: u"pending"
        })
        
        (map-set tools tool-id (merge tool { status: u"requested" }))
        (var-set next-request-id (+ request-id u1))
        (ok request-id)
    )
)

(define-public (approve-borrow (request-id uint))
    (let
        (
            (request (unwrap! (map-get? borrow-requests request-id) ERR-REQUEST-NOT-FOUND))
            (tool-id (get tool-id request))
            (tool (unwrap! (map-get? tools tool-id) ERR-TOOL-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get owner request)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status request) u"pending") ERR-REQUEST-INVALID-STATUS)
        
        (map-set borrow-requests request-id (merge request { status: u"approved" }))
        (map-set tools tool-id (merge tool { status: u"borrowed" }))
        
        (ok true)
    )
)

(define-public (deny-borrow (request-id uint))
    (let
        (
            (request (unwrap! (map-get? borrow-requests request-id) ERR-REQUEST-NOT-FOUND))
            (tool-id (get tool-id request))
            (tool (unwrap! (map-get? tools tool-id) ERR-TOOL-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get owner request)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status request) u"pending") ERR-REQUEST-INVALID-STATUS)
        
        (map-set borrow-requests request-id (merge request { status: u"denied" }))
        (map-set tools tool-id (merge tool { status: u"available" }))
        
        (ok true)
    )
)

(define-public (return-tool (request-id uint))
    (let
        (
            (request (unwrap! (map-get? borrow-requests request-id) ERR-REQUEST-NOT-FOUND))
            (tool-id (get tool-id request))
            (tool (unwrap! (map-get? tools tool-id) ERR-TOOL-NOT-FOUND))
        )
        (asserts! (or (is-eq tx-sender (get borrower request)) (is-eq tx-sender (get owner request))) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status request) u"approved") ERR-REQUEST-INVALID-STATUS)
        
        (map-set borrow-requests request-id (merge request { status: u"returned" }))
        (map-set tools tool-id (merge tool { status: u"available" }))
        
        (ok true)
    )
)

(define-read-only (get-tool (tool-id uint))
    (ok (map-get? tools tool-id))
)

(define-read-only (get-owner (tool-id uint))
    (ok (get owner (unwrap! (map-get? tools tool-id) ERR-TOOL-NOT-FOUND)))
)

(define-read-only (get-borrow-request (request-id uint))
    (ok (map-get? borrow-requests request-id))
)
