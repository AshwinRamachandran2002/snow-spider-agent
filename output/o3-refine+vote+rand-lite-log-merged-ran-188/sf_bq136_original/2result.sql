/* -----------------------------------------------------------------
   2–hop paths  (source ➜ intermediate ➜ destination)  on Zilliqa
   – regular TRANSACTIONS  (sender ➜ to_addr)
   – contract   TRANSITIONS (addr   ➜ recipient)
   – keep the source even if it has > 50 out‑txs, otherwise
     exclude addresses with more than 50 outgoing transfers
------------------------------------------------------------------*/
WITH
/* 1.  All directed, confirmed transfers */
edges AS (
    SELECT
        "sender"          AS from_addr,
        "to_addr"         AS to_addr,
        "block_timestamp" AS ts,
        "id"              AS tx_id
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "success" = TRUE
      AND  "to_addr" IS NOT NULL

    UNION ALL

    SELECT
        "addr"            AS from_addr,
        "recipient"       AS to_addr,
        "block_timestamp" AS ts,
        "transaction_id"  AS tx_id
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "recipient" IS NOT NULL
      AND  "addr" IS NOT NULL
),

/* 2.  Outgoing‑tx count per address */
out_cnt AS (
    SELECT  from_addr, COUNT(*) AS cnt
    FROM    edges
    GROUP BY from_addr
),

/* 3.  Filter: keep source unconditionally; others ≤ 50 out‑txs */
filtered_edges AS (
    SELECT  e.*
    FROM    edges e
    LEFT JOIN out_cnt c
           ON e.from_addr = c.from_addr
    WHERE   e.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
        OR  COALESCE(c.cnt,0) <= 50
),

/* 4.  First hop:  source ➜ intermediate */
first_hop AS (
    SELECT *
    FROM   filtered_edges
    WHERE  from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),

/* 5.  Second hop: intermediate ➜ destination */
second_hop AS (
    SELECT *
    FROM   filtered_edges
    WHERE  to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)

SELECT
      first_hop.from_addr
   || ' --(tx ' || SUBSTR(first_hop.tx_id,1,5)  || '...)--> '
   || first_hop.to_addr
   || ' --(tx ' || SUBSTR(second_hop.tx_id,1,5) || '...)--> '
   || second_hop.to_addr       AS "PATH"
FROM   first_hop
JOIN   second_hop
      ON  first_hop.to_addr = second_hop.from_addr      -- same intermediate
     AND first_hop.ts      < second_hop.ts              -- chronological
ORDER BY "PATH";