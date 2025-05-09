WITH
-- all confirmed outward transfers (regular txs + contract transitions)
edges AS (
    SELECT
        "sender"      AS "from_addr",
        "to_addr"     AS "to_addr",
        "id"          AS "tx_id",
        "block_timestamp"  AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE
      AND "to_addr" IS NOT NULL
    
    UNION ALL
    
    SELECT
        "addr"        AS "from_addr",
        "recipient"   AS "to_addr",
        "transaction_id" AS "tx_id",
        "block_timestamp" AS "ts"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "recipient" IS NOT NULL
),
-- outgoing-transaction count per address (used to filter busy wallets / exchanges)
out_degree AS (
    SELECT
        "from_addr",
        COUNT(*) AS "out_cnt"
    FROM edges
    GROUP BY "from_addr"
),
-- first hop : from SOURCE to some intermediate address
hop1 AS (
    SELECT
        e."to_addr"  AS "mid_addr",
        e."tx_id"    AS "tx1_id",
        e."ts"       AS "ts1"
    FROM edges e
    WHERE e."from_addr" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
-- second hop : from the same intermediate address to DESTINATION
hop2 AS (
    SELECT
        e."from_addr" AS "mid_addr",
        e."tx_id"     AS "tx2_id",
        e."ts"        AS "ts2"
    FROM edges e
    WHERE e."to_addr" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)
-- combine the two hops, enforce chronological order and filter busy intermediates
SELECT
    CONCAT(
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
        ' --(tx ', SUBSTR(h1."tx1_id",1,5), '..)--> ',
        h1."mid_addr",
        ' --(tx ', SUBSTR(h2."tx2_id",1,5), '..)--> ',
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
    ) AS "transaction_path"
FROM hop1 h1
JOIN hop2 h2
      ON  h1."mid_addr" = h2."mid_addr"
     AND h1."ts1"       < h2."ts2"                     -- chronological order
JOIN out_degree od
      ON od."from_addr" = h1."mid_addr"
WHERE od."out_cnt" <= 50                               -- filter high-activity wallets
ORDER BY h1."ts1" ASC;