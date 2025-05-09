WITH eligible_tx AS (     -- successful transactions (before 2021-09-01) whose traces do NOT use the excluded call types
    SELECT
        "hash",
        "from_address"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE t."block_timestamp" < 1630454400000000          -- 2021-09-01 00:00:00 UTC (micro-seconds)
      AND t."receipt_status" = 1
      AND NOT EXISTS (
            SELECT 1
            FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
            WHERE tr."transaction_hash" = t."hash"
              AND tr."call_type" IN ('delegatecall','callcode','staticcall')
      )
),
top_sender AS (          -- address with the most such transactions
    SELECT "from_address" AS "addr"
    FROM eligible_tx
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
relevant_traces AS (     -- all value-moving traces to be counted for the balance
    SELECT
        "to_address",
        "from_address",
        "value"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "block_timestamp" < 1630454400000000
      AND "status" = 1
      AND "value" IS NOT NULL
      AND "value" <> 0
      AND ( "call_type" IS NULL
            OR "call_type" NOT IN ('delegatecall','callcode','staticcall') )
),
balance_changes AS (     -- positive for receiver, negative for sender
    SELECT "to_address"   AS "addr",
           CAST("value" AS NUMBER(38,0))        AS "delta"
    FROM   relevant_traces

    UNION ALL

    SELECT "from_address" AS "addr",
           -CAST("value" AS NUMBER(38,0))       AS "delta"
    FROM   relevant_traces
    WHERE  "from_address" IS NOT NULL
),
final_balance_wei AS (   -- net Wei balance for the top sender
    SELECT SUM("delta")  AS "balance_wei"
    FROM   balance_changes
    WHERE  "addr" = (SELECT "addr" FROM top_sender)
)
SELECT
    "balance_wei" / 1000000000000000000            AS "FINAL_BALANCE_ETHER"
FROM final_balance_wei;