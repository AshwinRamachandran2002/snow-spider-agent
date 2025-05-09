WITH valid_tx AS (   -- successful transactions before 1‑Sep‑2021 (UTC) whose traces do NOT contain the excluded call‑types
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        CAST(t."value" AS NUMBER(38,0))                             AS "value_wei",
        t."receipt_gas_used",
        t."receipt_effective_gas_price"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE t."block_timestamp" < 1630454400000000                    -- 2021‑09‑01 00:00:00 UTC (µs)
      AND t."receipt_status" = 1
      AND NOT EXISTS (                                              -- exclude delegatecall / callcode / staticcall
            SELECT 1
            FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
            WHERE tr."transaction_hash" = t."hash"
              AND UPPER(COALESCE(tr."call_type",'CALL')) IN ('DELEGATECALL','CALLCODE','STATICCALL')
      )
),
top_addr AS (        -- address that initiated the greatest number of such transactions
    SELECT "from_address" AS "address"
    FROM   valid_tx
    GROUP  BY "from_address"
    ORDER  BY COUNT(*) DESC NULLS LAST, "from_address"
    LIMIT  1
),
-- outgoing ETH (value + gas) for that address
outgoing AS (
    SELECT v.*
    FROM   valid_tx v
    JOIN   top_addr a ON v."from_address" = a."address"
),
outgoing_sum AS (
    SELECT
        SUM("value_wei")                                           AS "sent_wei",
        SUM("receipt_gas_used" * "receipt_effective_gas_price")    AS "gas_wei"
    FROM outgoing
),
-- incoming ETH transfers to that address
incoming_sum AS (
    SELECT
        SUM(CAST(t."value" AS NUMBER(38,0))) AS "recv_wei"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN   top_addr a ON t."to_address" = a."address"
    WHERE  t."block_timestamp" < 1630454400000000
      AND  t."receipt_status" = 1
),
-- final balance in Ether
balance AS (
    SELECT
        (COALESCE(i."recv_wei",0) - COALESCE(o."sent_wei",0) - COALESCE(o."gas_wei",0)) / 1e18 AS "final_balance_eth"
    FROM outgoing_sum o
    CROSS JOIN incoming_sum i
)
SELECT
    a."address"                                 AS "ethereum_address",
    b."final_balance_eth"                       AS "final_balance_ether"
FROM   top_addr a
CROSS  JOIN balance b;