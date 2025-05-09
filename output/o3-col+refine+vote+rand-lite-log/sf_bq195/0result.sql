/*  Top-10 Ethereum addresses by net balance (value in – (value out + gas fee out))
    considering only successful transactions whose traces have
    call_type IS NULL or 'call', up to (but not including) 1-Sep-2021. */
WITH ok_traces AS (           -- Transactions whose traces are 'normal calls' and successful
    SELECT DISTINCT
           "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "status" = 1
      AND  ( "call_type" IS NULL OR "call_type" = 'call' )
), tx AS (                    -- Successful transactions that satisfy the trace filter & date
    SELECT  t."hash",
            t."from_address",
            t."to_address",
            /* numeric helpers */
            TO_NUMBER(t."value")                                            AS val,
            TO_NUMBER(t."receipt_gas_used")                                 AS gas_used,
            TO_NUMBER(COALESCE(t."receipt_effective_gas_price",
                               t."gas_price"))                              AS gas_price
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN    ok_traces o
           ON t."hash" = o."transaction_hash"
    WHERE   t."receipt_status" = 1
      AND   t."block_timestamp" < 1630454400000000        -- 2021-09-01 UTC
), balance_events AS (        -- Value in / out & gas-fee out, expressed as positive amounts
    /* incoming value */
    SELECT  "to_address"   AS addr,
            TO_NUMBER(val) AS amount,
            1              AS sign         -- +1 for incoming
    FROM    tx
    UNION ALL
    /* outgoing value + gas fee */
    SELECT  "from_address"                                    AS addr,
            TO_NUMBER(val + gas_used * gas_price)             AS amount,
            -1                                                AS sign -- -1 for outgoing
    FROM    tx
)
SELECT  addr                     AS "ethereum_address",
        SUM(sign * amount)       AS "net_balance_wei"
FROM    balance_events
GROUP  BY addr
ORDER BY "net_balance_wei" DESC NULLS LAST
LIMIT   10;