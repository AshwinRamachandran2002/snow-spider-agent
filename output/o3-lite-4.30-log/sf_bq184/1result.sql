WITH baseline AS (   -- contracts created before 2017‑01‑01
    SELECT
        COALESCE(SUM(CASE WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 1 END),0) AS "external_before",
        COALESCE(SUM(CASE WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' THEN 1 END),0) AS "internal_before"
    FROM   "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE  "trace_type" = 'create'
      AND  TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) < '2017-01-01'
),
calendar AS (        -- every day from 2017‑01‑01 through 2021‑12‑31 (1826 rows)
    SELECT DATEADD(day, seq4(), '2017-01-01') AS "date"
    FROM   TABLE(GENERATOR(ROWCOUNT => 1826))
),
daily_creates AS (   -- per‑day contract creations within the window
    SELECT
        DATE_TRUNC('day',
                   TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))                           AS "date",
        SUM(CASE WHEN "trace_address" IS NULL OR "trace_address" = ''  THEN 1 ELSE 0 END)  AS "external_cnt",
        SUM(CASE WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' THEN 1 ELSE 0 END) AS "internal_cnt"
    FROM   "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE  "trace_type" = 'create'
      AND  TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
           BETWEEN '2017-01-01' AND '2021-12-31 23:59:59'
    GROUP BY 1
),
merged AS (          -- calendar with zero‑filled daily counts
    SELECT
        c."date",
        COALESCE(d."external_cnt",0) AS "day_external",
        COALESCE(d."internal_cnt",0) AS "day_internal"
    FROM   calendar c
    LEFT   JOIN daily_creates d
           ON c."date" = d."date"
)
SELECT
    TO_CHAR("date",'YYYY-MM-DD')                                           AS "date",
    (SELECT "external_before" FROM baseline)
      + SUM("day_external") OVER (ORDER BY "date")                         AS "cumulative_external_creation",
    (SELECT "internal_before" FROM baseline)
      + SUM("day_internal") OVER (ORDER BY "date")                         AS "cumulative_internal_creation"
FROM   merged
ORDER  BY "date";