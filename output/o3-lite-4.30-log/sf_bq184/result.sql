WITH dates AS (                       -- every calendar day in the range
    SELECT DATEADD(day, seq4(), DATE '2017-01-01') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))          -- > 1 826 needed rows
    WHERE DATEADD(day, seq4(), DATE '2017-01-01') <= DATE '2021-12-31'
),
daily_creations AS (                  -- contracts created each day
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))            AS "date",
        SUM(CASE WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 1 ELSE 0 END) AS "external_cnt",
        SUM(CASE WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' THEN 1 ELSE 0 END) AS "internal_cnt"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE "trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
          BETWEEN DATE '2017-01-01' AND DATE '2021-12-31'
    GROUP BY 1
),
dated_counts AS (                     -- ensure every date is present
    SELECT
        d."date",
        COALESCE(c."external_cnt", 0) AS "external_cnt",
        COALESCE(c."internal_cnt", 0) AS "internal_cnt"
    FROM dates d
    LEFT JOIN daily_creations c
           ON d."date" = c."date"
)
SELECT
    "date",
    SUM("external_cnt") OVER (ORDER BY "date") AS "cumulative_external_creation",
    SUM("internal_cnt") OVER (ORDER BY "date") AS "cumulative_internal_creation"
FROM dated_counts
ORDER BY "date";