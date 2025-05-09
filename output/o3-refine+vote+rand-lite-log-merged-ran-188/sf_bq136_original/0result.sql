WITH 

/* -----------------------------------------------------------------
   Gather all confirmed value‑transfers on Zilliqa
   -----------------------------------------------------------------*/
edges AS (       
    /* regular transactions */
    SELECT  
        "sender"          AS from_addr ,
        "to_addr"         AS to_addr  ,
        "id"              AS txid     ,
        "block_timestamp" AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE  "success" = TRUE
      AND  "to_addr" IS NOT NULL              

    UNION ALL           

    /* contract transitions that move value */
    SELECT  
        "addr"            AS from_addr ,
        "recipient"       AS to_addr  ,
        "transaction_id"  AS txid     ,
        "block_timestamp" AS ts
    FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE  "accepted" = FALSE
      AND  "recipient" IS NOT NULL
),

/* -----------------------------------------------------------------
   Count outgoing txs per address so we can filter “high‑activity” ones
   -----------------------------------------------------------------*/
out_counts AS (
    SELECT from_addr , COUNT(*) AS out_tx
    FROM   edges
    GROUP  BY from_addr
),

/* -----------------------------------------------------------------
   Keep only edges whose sender has ≤ 50 outgoing txs
   -----------------------------------------------------------------*/
filtered_edges AS (
    SELECT e.*
    FROM   edges      e
    JOIN   out_counts c
      ON   e.from_addr = c.from_addr
    WHERE  c.out_tx <= 50
),

/* -----------------------------------------------------------------
   1st hop : from SOURCE ➜ any intermediate
   -----------------------------------------------------------------*/
edge1 AS (
    SELECT *
    FROM   filtered_edges
    WHERE  from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),

/* -----------------------------------------------------------------
   2nd hop : from same intermediate ➜ DESTINATION
   -----------------------------------------------------------------*/
edge2 AS (
    SELECT *
    FROM   filtered_edges
    WHERE  to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
),

/* -----------------------------------------------------------------
   Build paths (may be empty)
   -----------------------------------------------------------------*/
paths AS (
SELECT DISTINCT
       CONCAT(
           'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
           ' --(tx ', SUBSTR(e1.txid, 1, 5), ')--> ',
           e1.to_addr,
           ' --(tx ', SUBSTR(e2.txid, 1, 5), ')--> ',
           'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
       ) AS path
FROM   edge1 e1
JOIN   edge2 e2
       ON e1.to_addr = e2.from_addr        -- same intermediate
      AND e1.ts      < e2.ts               -- chronological order
      AND e1.to_addr NOT IN (
              'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
              'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
          )
)

/* -----------------------------------------------------------------
   Return paths; if none exist return the literal 'NO_PATH'
   -----------------------------------------------------------------*/
SELECT path
FROM   paths

UNION ALL

SELECT 'NO_PATH'  -- fallback row so query always returns at least one record
WHERE  NOT EXISTS (SELECT 1 FROM paths);