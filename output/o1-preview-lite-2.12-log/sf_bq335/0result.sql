WITH addr_transactions AS (
    SELECT
        f.value::STRING AS "address",
        t."block_timestamp",
        t."value"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."INPUTS" t,
         LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1506816000000000 AND t."block_timestamp" < 1509494400000000

    UNION ALL

    SELECT
        f.value::STRING AS "address",
        t."block_timestamp",
        t."value"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" t,
         LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1506816000000000 AND t."block_timestamp" < 1509494400000000
),
addr_summary AS (
    SELECT
        "address",
        MAX("block_timestamp") AS "last_transaction_timestamp",
        SUM("value") AS "total_transaction_value"
    FROM addr_transactions
    GROUP BY "address"
),
latest_timestamp AS (
    SELECT MAX("last_transaction_timestamp") AS "latest_timestamp" FROM addr_summary
)
SELECT
    a."address",
    TO_DATE(TO_TIMESTAMP_NTZ(a."last_transaction_timestamp" / 1e6)) AS "last_transaction_date",
    ROUND(a."total_transaction_value", 4) AS "total_transaction_value"
FROM addr_summary a
WHERE a."last_transaction_timestamp" = (SELECT "latest_timestamp" FROM latest_timestamp)
ORDER BY a."total_transaction_value" DESC NULLS LAST
LIMIT 1;