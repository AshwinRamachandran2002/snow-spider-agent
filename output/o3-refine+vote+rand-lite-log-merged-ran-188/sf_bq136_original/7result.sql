WITH
/* ------------------------------------------------------------------ */
/* 1.  Build a directed edge list from both regular txs and contracts */
/* ------------------------------------------------------------------ */
EDGES AS (
    /* regular (payment) transactions */
    SELECT
        "id"              AS tx_id,
        "block_timestamp" AS ts,
        "sender"          AS from_addr,
        "to_addr"         AS to_addr
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL

    UNION ALL

    /* contract‑originated transfers recorded in TRANSITIONS                *
     * `addr`     – contract address that CALLs send                          *
     * `recipient`– address that receives                                     */
    SELECT
        "transaction_id"  AS tx_id,
        "block_timestamp" AS ts,
        "addr"            AS from_addr,
        "recipient"       AS to_addr
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),
/* ------------------------------------------------------------------ */
/* 2.  How “busy” is every address as a sender?                       */
/* ------------------------------------------------------------------ */
OUTGO AS (
    SELECT from_addr, COUNT(*) AS out_cnt
    FROM EDGES
    GROUP BY from_addr
),
/* ------------------------------------------------------------------ */
/* 3.  First‑hop candidates  (source  →  intermediate)                */
/* ------------------------------------------------------------------ */
FIRST_HOP AS (
    SELECT
        e.tx_id      AS tx1_id,
        e.ts         AS ts1,
        e.to_addr    AS interm
    FROM EDGES e
    WHERE e.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
/* ------------------------------------------------------------------ */
/* 4.  Second‑hop candidates  (intermediate  →  destination)          */
/*     – keep only intermediates with ≤ 50 outgoing txs               */
/* ------------------------------------------------------------------ */
SECOND_HOP AS (
    SELECT
        f.tx1_id,
        f.ts1,
        f.interm,
        e.tx_id      AS tx2_id,
        e.ts         AS ts2
    FROM FIRST_HOP     f
    JOIN EDGES         e   ON e.from_addr = f.interm
    JOIN OUTGO         o   ON o.from_addr = f.interm
    WHERE o.out_cnt <= 50                                   -- low‑activity wallet
      AND e.to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
      AND e.ts      > f.ts1                                 -- chronological order
)
/* ------------------------------------------------------------------ */
/* 5.  Present distinct 2‑hop paths                                   */
/* ------------------------------------------------------------------ */
SELECT DISTINCT
       CONCAT(
           'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
           ' --(tx ', SUBSTR(tx1_id,1,5), '..)--> ',
           interm,
           ' --(tx ', SUBSTR(tx2_id,1,5), '..)--> ',
           'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
       ) AS "PATH"
FROM SECOND_HOP
ORDER BY "PATH";