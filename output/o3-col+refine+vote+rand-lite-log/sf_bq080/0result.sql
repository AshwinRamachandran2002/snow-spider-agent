WITH
-- 1. Calendar covering every day from 2018-08-30 to 2018-09-30 (32 days)
calendar AS (
    SELECT
        DATEADD(day, seq4(), DATE '2018-08-30') AS "event_day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))      -- inclusive range
),

-- 2. Daily contract-creation counts initiated by EXTERNAL users
external_daily AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))  AS "event_day",
        COUNT(*)                                                     AS "ext_cnt"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type"    = 'create'
      AND  "trace_address" IS NULL
      AND  DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
           BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
    GROUP BY 1
),

-- 3. Daily contract-creation counts initiated by OTHER contracts
internal_daily AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))  AS "event_day",
        COUNT(*)                                                     AS "int_cnt"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type"    = 'create'
      AND  "trace_address" IS NOT NULL
      AND  DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
           BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
    GROUP BY 1
),

-- 4. Merge calendar with daily counts, filling missing days with zeros
combined AS (
    SELECT
        c."event_day",
        COALESCE(e."ext_cnt", 0) AS "ext_cnt",
        COALESCE(i."int_cnt", 0) AS "int_cnt"
    FROM   calendar         c
    LEFT   JOIN external_daily e ON e."event_day" = c."event_day"
    LEFT   JOIN internal_daily i ON i."event_day" = c."event_day"
),

-- 5. Compute cumulative (strictly non-decreasing) totals
cumulative AS (
    SELECT
        "event_day",
        SUM("ext_cnt") OVER (ORDER BY "event_day") AS "cum_external_creations",
        SUM("int_cnt") OVER (ORDER BY "event_day") AS "cum_internal_creations"
    FROM   combined
)

-- 6. Final result
SELECT *
FROM   cumulative
ORDER  BY "event_day";