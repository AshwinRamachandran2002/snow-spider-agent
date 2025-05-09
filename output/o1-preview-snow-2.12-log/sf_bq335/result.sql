SELECT
    a."address",
    TO_DATE(TO_TIMESTAMP_NTZ(a."last_transaction_timestamp"/1e6)) AS "last_transaction_date",
    a."total_transaction_value"
FROM (
    SELECT
        f.VALUE::STRING AS "address",
        MAX(t."block_timestamp") AS "last_transaction_timestamp",
        SUM(t."value") AS "total_transaction_value"
    FROM (
        SELECT "block_timestamp", "addresses", "value"
        FROM "CRYPTO"."CRYPTO_BITCOIN"."INPUTS"
        WHERE "block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
        UNION ALL
        SELECT "block_timestamp", "addresses", "value"
        FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
        WHERE "block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
    ) t,
    LATERAL FLATTEN(input => t."addresses") f
    GROUP BY f.VALUE
) a
WHERE a."last_transaction_timestamp" = (
    SELECT MAX("last_transaction_timestamp")
    FROM (
        SELECT
            f.VALUE::STRING AS "address",
            MAX(t."block_timestamp") AS "last_transaction_timestamp"
        FROM (
            SELECT "block_timestamp", "addresses"
            FROM "CRYPTO"."CRYPTO_BITCOIN"."INPUTS"
            WHERE "block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
            UNION ALL
            SELECT "block_timestamp", "addresses"
            FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
            WHERE "block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
        ) t,
        LATERAL FLATTEN(input => t."addresses") f
        GROUP BY f.VALUE
    )
)
ORDER BY a."total_transaction_value" DESC NULLS LAST
LIMIT 1;