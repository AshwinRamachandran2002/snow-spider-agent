WITH date_series AS (
    SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2017-01-01') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
),
daily_counts AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "date",
        COUNT(CASE WHEN "trace_address" IS NULL THEN 1 END) AS "external_creations",
        COUNT(CASE WHEN "trace_address" IS NOT NULL THEN 1 END) AS "internal_creations"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
        AND "block_timestamp" >= 1483228800000000  -- '2017-01-01' in microseconds
        AND "block_timestamp" < 1640908800000000   -- '2022-01-01' in microseconds
    GROUP BY "date"
)
SELECT
    d."date",
    SUM(COALESCE(dc."external_creations", 0)) OVER (ORDER BY d."date") AS "Cumulative_External_Creations",
    SUM(COALESCE(dc."internal_creations", 0)) OVER (ORDER BY d."date") AS "Cumulative_Internal_Creations"
FROM date_series d
LEFT JOIN daily_counts dc ON d."date" = dc."date"
ORDER BY d."date";