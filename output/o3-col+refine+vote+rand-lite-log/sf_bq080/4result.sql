/*  Daily cumulative smart-contract creations
    – external users   : trace_address IS NULL
    – internal (via contract) : trace_address IS NOT NULL
    Period: 30-Aug-2018 → 30-Sep-2018  (inclusive)                                               */

WITH
-- 1.  Full calendar for the requested interval (32 days)
"dates" AS (
    SELECT
        DATEADD(DAY, SEQ4(), '2018-08-30'::DATE) AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),

-- 2.  Contracts created per day, split by origin
"daily_counts" AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))                  AS "date",
        SUM(CASE WHEN "trace_address" IS NULL     THEN 1 ELSE 0 END)        AS "external_cnt",
        SUM(CASE WHEN "trace_address" IS NOT NULL THEN 1 ELSE 0 END)        AS "internal_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "block_timestamp" BETWEEN 1535587200000000          -- 2018-08-30 00:00:00 UTC
                              AND 1538351999000000            -- 2018-09-30 23:59:59 UTC
    GROUP BY 1
)

-- 3.  Join calendar with daily data and calculate running totals
SELECT
    d."date",
    SUM(COALESCE(c."external_cnt", 0)) OVER (ORDER BY d."date")  AS "external_cumulative",
    SUM(COALESCE(c."internal_cnt", 0)) OVER (ORDER BY d."date")  AS "internal_cumulative"
FROM "dates"            d
LEFT JOIN "daily_counts" c USING ("date")
ORDER BY d."date";