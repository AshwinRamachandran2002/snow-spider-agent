WITH tx AS (   -- external transactions on 14‑Oct‑2016 that succeeded
    SELECT
        "hash",
        "from_address",
        "to_address",
        "value"::NUMBER    AS value,
        "gas_price"::NUMBER AS gas_price,
        "receipt_gas_used"::NUMBER AS gas_used,
        ("gas_price"::NUMBER * "receipt_gas_used"::NUMBER) AS fee,
        "block_number",
        "block_timestamp"
    FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
    WHERE  "receipt_status" = 1
      AND  DATE( TO_TIMESTAMP( "block_timestamp" / 1000000 ) ) = '2016-10-14'
),
-- net change for transaction senders (value sent + gas fee paid)
sender_changes AS (
    SELECT
        "from_address"                       AS address,
        SUM( -(value + fee) )                AS net_change
    FROM tx
    GROUP BY "from_address"
),
-- net change for transaction recipients (value received)
recipient_changes AS (
    SELECT
        "to_address"                         AS address,
        SUM( value )                         AS net_change
    FROM tx
    GROUP BY "to_address"
),
-- gas fees earned by miners of the blocks that contain the transactions
miner_fees AS (
    SELECT
        b."miner"                            AS address,
        SUM( t.fee )                         AS net_change
    FROM tx t
    JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS b
          ON t."block_number" = b."number"
    GROUP BY b."miner"
),
-- aggregate all balance deltas per address
all_changes AS (
    SELECT * FROM sender_changes
    UNION ALL
    SELECT * FROM recipient_changes
    UNION ALL
    SELECT * FROM miner_fees
),
agg AS (
    SELECT
        address,
        SUM(net_change)  AS net_change
    FROM all_changes
    GROUP BY address
)
-- final maximum / minimum net balance change across all addresses
SELECT
    MAX(net_change)  AS max_net_balance_change,
    MIN(net_change)  AS min_net_balance_change
FROM agg;