WITH
-- yearly average from merged input/output records (kept only outputs)
"outputs_yearly_avg" AS (
    SELECT
        YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("value")                                    AS "outputs_avg"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    GROUP BY "year"
),
-- yearly average taken directly from transactions table
"tx_yearly_avg" AS (
    SELECT
        YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("output_value")                             AS "tx_avg"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)
SELECT
    o."year",
    o."outputs_avg" - t."tx_avg" AS "avg_diff"
FROM "outputs_yearly_avg" o
JOIN "tx_yearly_avg"      t ON o."year" = t."year"
ORDER BY o."year" ASC NULLS LAST;