WITH edges AS (      -- all confirmed value‑transfers on Zilliqa
        /* regular txs */
        SELECT  "sender"      AS "from_addr",
                "to_addr"     AS "to_addr",
                "id"          AS "tx_id",
                "block_timestamp" AS "ts"
        FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
        WHERE   "success" = TRUE
          AND   "to_addr" IS NOT NULL

        UNION ALL            -- contract‑generated transfers
        SELECT  "addr"           AS "from_addr",
                "recipient"      AS "to_addr",
                "transaction_id" AS "tx_id",
                "block_timestamp" AS "ts"
        FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
        WHERE   "recipient" IS NOT NULL
          AND   "depth" = 0                      -- top‑level calls only
),

/* how busy each address is on the sending side */
inter_out AS (
        SELECT  "from_addr",
                COUNT(*) AS out_cnt
        FROM    edges
        GROUP BY "from_addr"
),

/* admissible intermediate addresses (≤ 50 out‑txns) */
valid_inter AS (
        SELECT  "from_addr" AS "addr"
        FROM    inter_out
        WHERE   out_cnt <= 50
)

/* find 2‑hop chronological paths source → inter → destination */
SELECT  CONCAT(
            e1."from_addr",
            ' --(tx ', SUBSTR(e1."tx_id",1,5), ')--> ',
            e1."to_addr",
            ' --(tx ', SUBSTR(e2."tx_id",1,5), ')--> ',
            e2."to_addr"
        ) AS "path"
FROM    edges  e1
JOIN    edges  e2
          ON   e1."to_addr" = e2."from_addr"      -- hop through same inter
         AND   e1."ts"       < e2."ts"            -- chronological order
JOIN    valid_inter vi
          ON   vi."addr"     = e1."to_addr"       -- inter has low activity
WHERE   e1."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'  -- source
  AND   e2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'  -- destination
  AND   e1."to_addr" NOT IN ('zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
                             'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e') -- true inter
ORDER BY e1."ts", e2."ts";