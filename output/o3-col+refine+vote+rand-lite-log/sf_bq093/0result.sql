/*  Maximum and minimum net-balance change for all Ethereum Classic
    addresses on 14-Oct-2016 (UTC).  
    If the day has no qualifying transactions, the query still returns
    two rows with NULL address and 0 balance-change.                      */
WITH day_tx AS (   -- successful external transactions on 2016-10-14
    SELECT
        t."from_address",
        t."to_address",
        t."value",
        t."gas_price",
        t."receipt_gas_used",
        b."miner"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"  t
    JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS"        b
          ON t."block_number" = b."number"
    WHERE t."block_timestamp" >= 1476403200000000        -- 2016-10-14 00:00 UTC
      AND t."block_timestamp" <  1476489600000000        -- 2016-10-15 00:00 UTC
      AND t."receipt_status"  = 1                        -- successful
), address_changes AS (
    /* sender debits (value + gas) */
    SELECT
        "from_address" AS addr,
        -1 * SUM("value" + "gas_price" * "receipt_gas_used") AS net_change
    FROM day_tx
    GROUP BY "from_address"
    UNION ALL
    /* receiver credits (value) */
    SELECT
        "to_address"  AS addr,
        SUM("value")  AS net_change
    FROM day_tx
    GROUP BY "to_address"
    UNION ALL
    /* miner gas-fee rewards */
    SELECT
        "miner"       AS addr,
        SUM("gas_price" * "receipt_gas_used") AS net_change
    FROM day_tx
    GROUP BY "miner"
), aggregated AS (               -- net change per address
    SELECT
        addr,
        SUM(net_change) AS net_change
    FROM address_changes
    GROUP BY addr
), ranked AS (                   -- rank to pick max / min
    SELECT
        addr,
        net_change,
        ROW_NUMBER() OVER (ORDER BY net_change DESC NULLS LAST) AS rn_max,
        ROW_NUMBER() OVER (ORDER BY net_change ASC  NULLS LAST) AS rn_min
    FROM aggregated
)
SELECT 'MAX' AS kind, addr, net_change
FROM ranked
WHERE rn_max = 1

UNION ALL

SELECT 'MIN' AS kind, addr, net_change
FROM ranked
WHERE rn_min = 1

UNION ALL                          -- fallback when no data for the day
SELECT 'MAX' AS kind, NULL AS addr, 0 AS net_change
WHERE NOT EXISTS (SELECT 1 FROM ranked)

UNION ALL
SELECT 'MIN', NULL, 0
WHERE NOT EXISTS (SELECT 1 FROM ranked);