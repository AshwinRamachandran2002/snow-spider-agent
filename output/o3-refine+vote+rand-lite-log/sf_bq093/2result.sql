WITH txs AS (   -- successful transactions on 14‑Oct‑2016
    SELECT  "hash",
            LOWER("from_address")  AS from_addr,
            LOWER("to_address")    AS to_addr,
            "value"                AS val,
            "receipt_gas_used"     AS gas_used,
            "gas_price"            AS gas_price,
            ("receipt_gas_used" * "gas_price") AS fee,
            "block_hash"
    FROM    CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"
    WHERE   "receipt_status" = 1
      AND   TO_DATE( TO_TIMESTAMP("block_timestamp"/1e6) ) = '2016-10-14'
),
-- debit : value + fee paid by sender
debits AS (
    SELECT from_addr       AS address,
           -(val + fee)    AS delta
    FROM   txs
),
-- credit : value received by receiver
credits AS (
    SELECT to_addr         AS address,
           val             AS delta
    FROM   txs
    WHERE  to_addr IS NOT NULL
),
-- miner fee reward
miner_fees AS (
    SELECT  LOWER(b."miner")        AS address,
            SUM(t.fee)              AS delta
    FROM    txs  t
    JOIN    CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS" b
           ON b."hash" = t."block_hash"
    GROUP BY LOWER(b."miner")
),
-- combine all balance changes
all_changes AS (
    SELECT * FROM debits
    UNION ALL
    SELECT * FROM credits
    UNION ALL
    SELECT * FROM miner_fees
),
net_changes AS (   -- net change per address
    SELECT  address,
            SUM(delta) AS net_change
    FROM    all_changes
    WHERE   address IS NOT NULL
    GROUP BY address
)
SELECT  MAX(net_change) AS "MAX_NET_CHANGE",
        MIN(net_change) AS "MIN_NET_CHANGE"
FROM    net_changes;