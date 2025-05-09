WITH
-- Transactions since July 1, 2023
txns AS (
    SELECT
        t."hash",
        t."block_timestamp_month" AS Month,
        t."input_count",
        t."output_count",
        t."input_value",
        t."output_value"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS" t
    WHERE t."block_timestamp_month" >= '2023-07-01'
),

-- CoinJoin transactions
coinjoin_txns AS (
    SELECT
        t."hash"
    FROM txns t
    JOIN "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" o ON t."hash" = o."transaction_hash"
    GROUP BY t."hash", t."input_count", t."output_count"
    HAVING
        t."input_count" >= 5 AND
        t."output_count" >= 5 AND
        MIN(o."value") = MAX(o."value")
),

-- Annotate transactions with CoinJoin flag
annotated_txns AS (
    SELECT
        t.*,
        CASE WHEN cj."hash" IS NOT NULL THEN 1 ELSE 0 END AS is_coinjoin
    FROM txns t
    LEFT JOIN coinjoin_txns cj ON t."hash" = cj."hash"
)

-- Calculate percentages per month
SELECT
    TO_CHAR(Month, 'Mon-YYYY') AS Month,
    ROUND((SUM(is_coinjoin) * 100.0) / COUNT(*), 4) AS Percentage_of_CoinJoin_Transactions,
    ROUND((SUM(CASE WHEN is_coinjoin = 1 THEN "output_count" ELSE 0 END) * 100.0) / SUM("output_count"), 4) AS Percentage_of_CoinJoin_UTXOs,
    ROUND((SUM(CASE WHEN is_coinjoin = 1 THEN "output_value" ELSE 0 END) * 100.0) / SUM("output_value"), 4) AS Percentage_of_CoinJoin_Volume
FROM annotated_txns
GROUP BY Month
ORDER BY Month;