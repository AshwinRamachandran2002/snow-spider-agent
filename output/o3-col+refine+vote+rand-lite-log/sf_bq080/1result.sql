WITH
/* 1. Calendar covering every day from 30-Aug-2018 through 30-Sep-2018 (32 days) */
calendar AS (
    SELECT
        DATEADD('day', SEQ4(), TO_DATE('2018-08-30')) AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))      -- 32 days inclusive
),

/* 2. Daily counts of contracts created directly by EOAs (root-level traces) */
external_daily AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) AS "day",
        COUNT(*)                                                 AS "external_creations"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  ( "trace_address" IS NULL OR TRIM("trace_address") = '' )
      AND  "block_timestamp" BETWEEN 1535587200000000  -- 30-Aug-2018 00:00:00 UTC
                               AND     1538351999000000  -- 30-Sep-2018 23:59:59 UTC
    GROUP BY 1
),

/* 3. Daily counts of contracts created by other contracts (internal traces) */
internal_daily AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6)) AS "day",
        COUNT(*)                                                 AS "internal_creations"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  "trace_address" IS NOT NULL
      AND  TRIM("trace_address") <> ''
      AND  "block_timestamp" BETWEEN 1535587200000000
                               AND     1538351999000000
    GROUP BY 1
),

/* 4. Merge calendar with daily counts, filling missing dates with zeros */
daily AS (
    SELECT
        c."day",
        COALESCE(e."external_creations", 0) AS "external_creations",
        COALESCE(i."internal_creations", 0) AS "internal_creations"
    FROM   calendar            c
    LEFT   JOIN external_daily e USING ("day")
    LEFT   JOIN internal_daily i USING ("day")
)

/* 5. Compute running (cumulative) totals */
SELECT
    "day",
    SUM("external_creations") OVER (ORDER BY "day") AS "cum_external_creations",
    SUM("internal_creations") OVER (ORDER BY "day") AS "cum_internal_creations"
FROM   daily
ORDER  BY "day";