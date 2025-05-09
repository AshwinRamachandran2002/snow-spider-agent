/* Daily cumulative count of Ethereum contract creations
   (EOA-originated vs contract-originated) from 2017-01-01 to 2021-12-31 */

WITH
/* 1. Parameter dates */
params AS (
    SELECT
        TO_DATE('2017-01-01') AS "start_date",
        TO_DATE('2021-12-31') AS "end_date"
),

/* 2. Calendar spine (one row per day) */
calendar AS (
    SELECT
        DATEADD(day, SEQ4(), p."start_date") AS "cal_date"
    FROM   params p,
           TABLE(GENERATOR(ROWCOUNT => 2000))          -- constant upper-bound
    WHERE  SEQ4() <= DATEDIFF(day, p."start_date", p."end_date")
),

/* 3. Creator categories */
categories AS (
    SELECT 'EOA'       AS "creator_type" UNION ALL
    SELECT 'CONTRACT'  AS "creator_type"
),

/* 4. Daily counts of contract-creation traces */
daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ(FLOOR("block_timestamp" / 1000000)))
                                                          AS "event_date",
        CASE WHEN "trace_address" IS NULL
                  THEN 'EOA'
             ELSE 'CONTRACT'
        END                                               AS "creator_type",
        COUNT(*)                                          AS "daily_creations"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  "block_timestamp"
             BETWEEN 1483228800000000   -- 2017-01-01 00:00:00
                 AND 1640995199000000   -- 2021-12-31 23:59:59
    GROUP  BY 1, 2
),

/* 5. Ensure every date / category pair exists */
spine AS (
    SELECT
        c."cal_date"     AS "event_date",
        cat."creator_type"
    FROM   calendar  c
    CROSS  JOIN categories cat
),

/* 6. Combine spine with actual data, filling gaps with zeros */
combined AS (
    SELECT
        s."event_date",
        s."creator_type",
        COALESCE(d."daily_creations", 0) AS "daily_creations"
    FROM   spine  s
    LEFT   JOIN daily d
           ON  s."event_date"   = d."event_date"
           AND s."creator_type" = d."creator_type"
)

/* 7. Final cumulative totals */
SELECT
    "event_date",
    "creator_type",
    SUM("daily_creations") OVER (PARTITION BY "creator_type"
                                 ORDER BY      "event_date")
        AS "cumulative_creations"
FROM   combined
ORDER  BY "event_date", "creator_type";