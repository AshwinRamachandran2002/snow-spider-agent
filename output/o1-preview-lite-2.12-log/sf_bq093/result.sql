WITH transaction_debits AS (
    SELECT 
        "from_address" AS "address",
        -("value" + COALESCE("gas_price", 0) * COALESCE("receipt_gas_used", 0)) AS "net_change"
    FROM 
        "CRYPTO"."CRYPTO_ETHEREUM_CLASSIC"."TRANSACTIONS"
    WHERE 
        DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = '2016-10-14'
),
transaction_credits AS (
    SELECT 
        "to_address" AS "address",
        "value" AS "net_change"
    FROM 
        "CRYPTO"."CRYPTO_ETHEREUM_CLASSIC"."TRANSACTIONS"
    WHERE 
        DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = '2016-10-14'
),
trace_debits AS (
    SELECT 
        "from_address" AS "address",
        - "value" AS "net_change"
    FROM 
        "CRYPTO"."CRYPTO_ETHEREUM_CLASSIC"."TRACES"
    WHERE 
        DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = '2016-10-14'
        AND ("call_type" IS NULL OR "call_type" NOT IN ('delegatecall', 'callcode', 'staticcall'))
),
trace_credits AS (
    SELECT 
        "to_address" AS "address",
        "value" AS "net_change"
    FROM 
        "CRYPTO"."CRYPTO_ETHEREUM_CLASSIC"."TRACES"
    WHERE 
        DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = '2016-10-14'
        AND ("call_type" IS NULL OR "call_type" NOT IN ('delegatecall', 'callcode', 'staticcall'))
),
all_net_changes AS (
    SELECT * FROM transaction_debits
    UNION ALL
    SELECT * FROM transaction_credits
    UNION ALL
    SELECT * FROM trace_debits
    UNION ALL
    SELECT * FROM trace_credits
),
net_changes_per_address AS (
    SELECT 
        "address", 
        ROUND(SUM("net_change"), 4) AS "total_net_change"
    FROM 
        all_net_changes
    GROUP BY 
        "address"
)
SELECT
    (SELECT "address" FROM net_changes_per_address ORDER BY "total_net_change" DESC NULLS LAST LIMIT 1) AS "Address_with_Max_Net_Change",
    (SELECT MAX("total_net_change") FROM net_changes_per_address) AS "Maximum_Net_Change",
    (SELECT "address" FROM net_changes_per_address ORDER BY "total_net_change" ASC NULLS LAST LIMIT 1) AS "Address_with_Min_Net_Change",
    (SELECT MIN("total_net_change") FROM net_changes_per_address) AS "Minimum_Net_Change";