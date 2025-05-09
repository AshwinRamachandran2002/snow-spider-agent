WITH date_span AS (          -- every calendar day in period (32 days inclusive)
    SELECT
        DATEADD(day, SEQ4(), DATE '2018-08-30') AS "event_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
daily_creations AS (         -- raw contract-creation counts per day
    SELECT
        CAST(TO_TIMESTAMP("block_timestamp" / 1e6) AS DATE)                                 AS "event_date",
        SUM(CASE WHEN "trace_address" IS NULL  THEN 1 ELSE 0 END)                          AS "external_cnt",
        SUM(CASE WHEN "trace_address" IS NOT NULL THEN 1 ELSE 0 END)                       AS "internal_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND CAST(TO_TIMESTAMP("block_timestamp" / 1e6) AS DATE)
          BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
    GROUP BY 1
),
all_days AS (                -- combine span with counts, fill missing with 0
    SELECT
        d."event_date",
        COALESCE(c."external_cnt", 0) AS "external_cnt",
        COALESCE(c."internal_cnt", 0) AS "internal_cnt"
    FROM date_span d
    LEFT JOIN daily_creations c
           ON d."event_date" = c."event_date"
)
SELECT
    "event_date",
    SUM("external_cnt") OVER (ORDER BY "event_date") AS "external_cumulative",
    SUM("internal_cnt") OVER (ORDER BY "event_date") AS "internal_cumulative"
FROM all_days
ORDER BY "event_date";