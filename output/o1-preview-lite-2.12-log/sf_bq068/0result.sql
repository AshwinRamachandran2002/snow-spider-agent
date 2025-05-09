WITH debits AS (
    SELECT
        f.value::STRING AS "address",
        t."type",
        SUM(t."value") AS "total_debit"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS AS t,
         LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1393632000000000 AND t."block_timestamp" < 1396310400000000
    GROUP BY "address", t."type"
),
credits AS (
    SELECT
        f.value::STRING AS "address",
        t."type",
        SUM(t."value") AS "total_credit"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS AS t,
         LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1393632000000000 AND t."block_timestamp" < 1396310400000000
    GROUP BY "address", t."type"
),
balances AS (
    SELECT
        COALESCE(credits."address", debits."address") AS "address",
        COALESCE(credits."type", debits."type") AS "type",
        COALESCE(credits."total_credit", 0) - COALESCE(debits."total_debit", 0) AS "final_balance"
    FROM credits
    FULL OUTER JOIN debits
        ON credits."address" = debits."address" AND credits."type" = debits."type"
)
SELECT
    "type",
    ROUND(MAX("final_balance"), 4) AS "maximum_final_balance",
    ROUND(MIN("final_balance"), 4) AS "minimum_final_balance"
FROM balances
GROUP BY "type";