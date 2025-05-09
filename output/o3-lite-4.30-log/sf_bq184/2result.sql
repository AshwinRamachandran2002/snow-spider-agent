WITH calendar AS (   -- every day from 2017‑01‑01 to 2021‑12‑31 (inclusive)
    SELECT DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS "date"
    FROM   TABLE(GENERATOR(ROWCOUNT => 1826))
),
daily_counts AS (    -- contracts created per day, split by origin
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6)) AS "date",
        SUM(CASE WHEN NULLIF(TRIM("trace_address"), '') IS NULL THEN 1 END)        AS external_cnt,
        SUM(CASE WHEN NULLIF(TRIM("trace_address"), '') IS NOT NULL THEN 1 END)    AS internal_cnt
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  "block_timestamp" BETWEEN 1483228800000000   -- 2017‑01‑01 00:00:00 UTC
                                AND     1640908800000000 -- 2021‑12‑31 00:00:00 UTC
    GROUP BY 1
)
SELECT
    c."date"                                                                                     AS "date",
    SUM(COALESCE(d.external_cnt, 0))  OVER (ORDER BY c."date")                                   AS "cumulative_external_creation",
    SUM(COALESCE(d.internal_cnt, 0))  OVER (ORDER BY c."date")                                   AS "cumulative_internal_creation"
FROM   calendar c
LEFT   JOIN daily_counts d
       ON c."date" = d."date"
ORDER  BY c."date";