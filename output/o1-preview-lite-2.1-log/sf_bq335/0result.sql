SELECT "address", ROUND("total_transaction_value", 4) AS "total_transaction_value"
FROM (
    SELECT
        "address",
        MAX("block_timestamp") AS "most_recent_timestamp",
        SUM("value") AS "total_transaction_value"
    FROM (
        SELECT f.value::STRING AS "address", t."block_timestamp", t."value"
        FROM "CRYPTO"."CRYPTO_BITCOIN"."INPUTS" t,
             LATERAL FLATTEN(input => t."addresses") f
        UNION ALL
        SELECT f.value::STRING AS "address", t."block_timestamp", t."value"
        FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" t,
             LATERAL FLATTEN(input => t."addresses") f
    ) transactions
    GROUP BY "address"
)
WHERE "most_recent_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
ORDER BY "total_transaction_value" DESC NULLS LAST
LIMIT 1;