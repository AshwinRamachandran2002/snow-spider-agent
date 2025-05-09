WITH
/* 1) One row for every calendar day from 2017-01-01 through 2021-12-31 */
date_range AS (
    SELECT
        DATEADD(day , seq4() , DATE '2017-01-01') AS event_date
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)          -- 5-year span (inclusive) = 1 826 days
    )
),

/* 2) Daily counts of contract-creation traces (external vs. internal) */
daily_creations AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))                 AS event_date,
        COUNT_IF("trace_address" IS NULL)                                  AS external_cnt,
        COUNT_IF("trace_address" IS NOT NULL)                              AS internal_cnt
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
           BETWEEN DATE '2017-01-01' AND DATE '2021-12-31'
    GROUP  BY event_date
),

/* 3) Ensure every date is represented, filling zeros where missing */
aligned AS (
    SELECT
        d.event_date,
        COALESCE(c.external_cnt , 0) AS daily_external,
        COALESCE(c.internal_cnt , 0) AS daily_internal
    FROM   date_range d
    LEFT   JOIN daily_creations c
           ON d.event_date = c.event_date
)

/* 4) Running cumulative totals for both categories */
SELECT
    event_date,
    SUM(daily_external) OVER (ORDER BY event_date) AS cumulative_external_creations,
    SUM(daily_internal) OVER (ORDER BY event_date) AS cumulative_internal_creations
FROM   aligned
ORDER  BY event_date;