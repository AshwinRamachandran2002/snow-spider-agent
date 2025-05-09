WITH calendar AS (   -- generate every date from 2017-01-01 through 2021-12-31
    SELECT 
        DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS "dt"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))      -- 365*5 + 1 leap-day = 1 826 rows
),
daily_counts AS (    -- count CREATE traces per day, split by origin
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) AS DATE)                   AS "dt",
        SUM(CASE WHEN "trace_address" IS NULL OR "trace_address" = '' 
                 THEN 1 ELSE 0 END)                                              AS "external_cnt",
        SUM(CASE WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' 
                 THEN 1 ELSE 0 END)                                              AS "internal_cnt"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) AS DATE)
           BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP  BY 1
),
by_day AS (         -- ensure every calendar date is present
    SELECT
        c."dt",
        COALESCE(d."external_cnt", 0) AS "external_cnt",
        COALESCE(d."internal_cnt", 0) AS "internal_cnt"
    FROM   calendar c
    LEFT   JOIN daily_counts d
           ON c."dt" = d."dt"
)
SELECT
    "dt",
    SUM("external_cnt") OVER (ORDER BY "dt") AS "external_cumulative",
    SUM("internal_cnt") OVER (ORDER BY "dt") AS "internal_cumulative"
FROM   by_day
ORDER  BY "dt";