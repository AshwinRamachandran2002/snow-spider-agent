/*  Top‑10 Ethereum addresses by NET balance (inflow – (outflow + gas fees))
    ‑ Only successful transactions (receipt_status = 1)
    ‑ Transaction hash must appear in a successful trace whose call_type is NULL or 'call'
    ‑ Only data before 1‑Sep‑2021 (1630454400000000 micro‑seconds)                     */

WITH good_traces AS (   -- qualifying traces
    SELECT DISTINCT
           "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "status" = 1
      AND  ( "call_type" IS NULL
             OR LOWER("call_type") = 'call' )
      AND  "block_timestamp" < 1630454400000000
),
filtered_tx AS (        -- successful transactions linked to those traces
    SELECT  t.*
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN    good_traces g
           ON g."transaction_hash" = t."hash"
    WHERE   t."receipt_status" = 1
      AND   t."block_timestamp" < 1630454400000000
),
inflow AS (             -- total ETH received
    SELECT  "to_address"                      AS "address",
            SUM("value")                      AS "total_in"
    FROM    filtered_tx
    GROUP BY "to_address"
),
outflow AS (            -- total ETH sent  +  paid gas fees
    SELECT  "from_address"                                          AS "address",
            SUM("value" + "receipt_gas_used" * "gas_price")         AS "total_out"
    FROM    filtered_tx
    GROUP BY "from_address"
),
balances AS (           -- merge inflow & outflow
    SELECT  COALESCE(i."address", o."address")            AS "address",
            COALESCE(i."total_in",  0)                    AS "total_in",
            COALESCE(o."total_out", 0)                    AS "total_out",
            COALESCE(i."total_in",0) - COALESCE(o."total_out",0)  AS "net_balance"
    FROM    inflow  i
    FULL JOIN outflow o
           ON i."address" = o."address"
)
SELECT  "address",
        "total_in",
        "total_out",
        "net_balance"
FROM    balances
ORDER BY "net_balance" DESC NULLS LAST,
         "address"
LIMIT 10;