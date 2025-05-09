WITH ordered AS (
    SELECT
        "number",
        "timestamp",
        TO_DATE(TO_TIMESTAMP("timestamp" / 1000000)) AS "block_date",
        ROW_NUMBER() OVER (ORDER BY "number") AS "rn"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "number" > 0                      -- exclude genesis block
),
pair AS (
    SELECT
        b1."block_date",
        (b1."timestamp" - b0."timestamp") / 1000000 AS "interval_seconds"   -- µs → s
    FROM ordered b1
    JOIN ordered b0
      ON b1."rn" = b0."rn" + 1             -- consecutive blocks
)
SELECT
    "block_date" AS "date",
    ROUND(AVG("interval_seconds"), 4) AS "unadjusted_avg_block_interval_seconds"
FROM pair
WHERE "block_date" BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;