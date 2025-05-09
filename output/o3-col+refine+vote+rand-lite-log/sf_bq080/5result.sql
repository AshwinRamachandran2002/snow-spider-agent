WITH
-- 1) calendar covering every day from 2018-08-30 through 2018-09-30 (32 days)
calendar AS (
    SELECT
        DATEADD('day', seq4(), DATE '2018-08-30') AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),

-- 2) daily count of contracts created directly by EOAs (root-level traces)
root_daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "day",
        COUNT(*)                                      AS "root_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND ( "trace_address" IS NULL OR "trace_address" = '' )
      AND "block_timestamp" BETWEEN 1535587200000000   -- 2018-08-30 00:00:00 UTC
                               AND 1538351999000000   -- 2018-09-30 23:59:59 UTC
    GROUP BY "day"
),

-- 3) daily count of contracts created by other contracts (internal traces)
internal_daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "day",
        COUNT(*)                                           AS "internal_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND ( "trace_address" IS NOT NULL AND "trace_address" <> '' )
      AND "block_timestamp" BETWEEN 1535587200000000
                               AND 1538351999000000
    GROUP BY "day"
),

-- 4) merge calendar with daily counts (fill zeros where missing)
daily AS (
    SELECT
        c."day",
        COALESCE(r."root_cnt",     0) AS "root_daily",
        COALESCE(i."internal_cnt", 0) AS "internal_daily"
    FROM calendar c
    LEFT JOIN root_daily     r USING ("day")
    LEFT JOIN internal_daily i USING ("day")
),

-- 5) running cumulative totals (monotonically non-decreasing)
cum AS (
    SELECT
        "day",
        SUM("root_daily")     OVER (ORDER BY "day") AS "cumulative_root",
        SUM("internal_daily") OVER (ORDER BY "day") AS "cumulative_internal"
    FROM daily
)

-- 6) final ordered result
SELECT
    "day",
    "cumulative_root",
    "cumulative_internal"
FROM cum
ORDER BY "day";