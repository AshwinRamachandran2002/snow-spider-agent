WITH
-- Calendar: every day from 2017-01-01 to 2021-12-31 (inclusive)
dates AS (
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01') AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))          -- 1 826 consecutive days
),

-- Daily counts of contract-creation traces
daily_creations AS (
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)  AS "day",
        COUNT_IF("trace_address" IS NULL)                              AS "external_cnt",
        COUNT_IF("trace_address" IS NOT NULL)                          AS "internal_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "block_timestamp" BETWEEN 1483228800000000   -- 2017-01-01
                               AND 1640995200000000 - 1 -- 2021-12-31 23:59:59.999…
    GROUP BY 1
)

-- Combine calendar with counts and compute cumulative totals
SELECT
    d."day",
    SUM(COALESCE(c."external_cnt", 0))
        OVER (ORDER BY d."day") AS "cumulative_external",
    SUM(COALESCE(c."internal_cnt", 0))
        OVER (ORDER BY d."day") AS "cumulative_internal"
FROM dates d
LEFT JOIN daily_creations c USING ("day")
ORDER BY d."day";