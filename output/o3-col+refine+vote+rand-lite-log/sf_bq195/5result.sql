WITH bad_traces AS (   -- transactions that include any non-simple call_type
    SELECT DISTINCT "transaction_hash"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000          -- 2021-09-01 UTC (µs)
      AND "call_type" IS NOT NULL
      AND "call_type" <> 'call'
),
good_tx AS (            -- successful txs with only NULL/'call' trace types
    SELECT  t.*
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    LEFT JOIN bad_traces b
           ON t."hash" = b."transaction_hash"
    WHERE   t."block_timestamp" < 1630454400000000
      AND   t."receipt_status" = 1
      AND   b."transaction_hash" IS NULL
),
deltas AS (             -- per-address balance deltas (value ± gas fee)
    /* sender side: subtract value and gas fee */
    SELECT
        "from_address"                    AS "addr",
        - ( "value" + ("gas_price" * "receipt_gas_used") )  AS "delta"
    FROM good_tx

    UNION ALL

    /* receiver side: add transferred value */
    SELECT
        "to_address"                      AS "addr",
        "value"                           AS "delta"
    FROM good_tx
    WHERE "to_address" IS NOT NULL
)
SELECT
    "addr"                                 AS "ethereum_address",
    SUM("delta") / 1e18                    AS "balance_eth"   -- wei → ETH
FROM deltas
WHERE "addr" IS NOT NULL
GROUP BY "addr"
ORDER BY "balance_eth" DESC NULLS LAST
LIMIT 10;