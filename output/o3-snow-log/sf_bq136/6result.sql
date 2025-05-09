WITH edges AS (

    /* regular transfers (confirmed, non-null target) */
    SELECT
        "id"                               AS "tx_id",
        LOWER("sender")                    AS "from_addr",
        LOWER("to_addr")                   AS "to_addr",
        "block_timestamp"                  AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL

    UNION ALL

    /* contract transitions that move ZIL (non-null recipient) */
    SELECT
        "transaction_id"                   AS "tx_id",
        LOWER("addr")                      AS "from_addr",
        LOWER("recipient")                 AS "to_addr",
        "block_timestamp"                  AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),

/* count of outgoing txs per address to filter high-activity wallets */
outgoing AS (
    SELECT "from_addr",
           COUNT(*) AS "cnt_out"
    FROM edges
    GROUP BY "from_addr"
),

/* first hop: source → intermediate                                                  */
first_hop AS (
    SELECT
        e1."tx_id"   AS "tx1",
        e1."to_addr" AS "mid_addr",
        e1."ts"      AS "ts1"
    FROM edges   e1
    WHERE e1."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),

/* second hop: intermediate → destination                                            */
second_hop AS (
    SELECT
        fh."tx1",
        fh."mid_addr",
        e2."tx_id" AS "tx2",
        e2."ts"    AS "ts2"
    FROM first_hop fh
    JOIN edges    e2
          ON e2."from_addr" = fh."mid_addr"
         AND e2."to_addr"   = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
         AND e2."ts"        > fh."ts1"                 -- chronological order
    JOIN outgoing o
          ON o."from_addr" = fh."mid_addr"
         AND o."cnt_out"  <= 50                       -- exclude busy wallets
)

/* final formatted paths                                                             */
SELECT DISTINCT
       CONCAT(
           'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
           ' --(tx ', SUBSTR("tx1",1,5), ')--> ',
           "mid_addr",
           ' --(tx ', SUBSTR("tx2",1,5), ')--> ',
           'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
       ) AS "2_hop_path"
FROM second_hop
ORDER BY "2_hop_path";