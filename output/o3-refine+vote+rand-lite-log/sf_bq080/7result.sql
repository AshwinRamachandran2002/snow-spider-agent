WITH date_range AS (                               -- calendar days
    SELECT 
        DATEADD(day, SEQ4(), DATE '2018-08-30') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))        -- 32 days 2018‑08‑30 … 2018‑09‑30
),
daily_creations AS (                              -- contracts created per day
    SELECT
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP("block_timestamp" / 1e6)
        )::DATE                              AS "date",
        CASE 
            WHEN "trace_address" IS NULL 
                 OR TRIM("trace_address") = '' THEN 'external'
            ELSE 'internal'
        END                                   AS "creator_type",
        COUNT(*)                              AS "cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND DATE_TRUNC(
              'day',
              TO_TIMESTAMP("block_timestamp" / 1e6)
          ) BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
    GROUP BY "date", "creator_type"
),
pivoted_daily AS (                                -- external vs internal counts
    SELECT
        "date",
        COALESCE(SUM(CASE WHEN "creator_type"='external' THEN "cnt" END),0)
            AS "external_cnt",
        COALESCE(SUM(CASE WHEN "creator_type"='internal' THEN "cnt" END),0)
            AS "internal_cnt"
    FROM daily_creations
    GROUP BY "date"
)
SELECT
    d."date",
    SUM(COALESCE(p."external_cnt",0)) OVER (ORDER BY d."date"
                                            ROWS BETWEEN UNBOUNDED PRECEDING
                                            AND CURRENT ROW)   AS "cumulative_external",
    SUM(COALESCE(p."internal_cnt",0)) OVER (ORDER BY d."date"
                                            ROWS BETWEEN UNBOUNDED PRECEDING
                                            AND CURRENT ROW)   AS "cumulative_internal"
FROM date_range AS d
LEFT JOIN pivoted_daily AS p
       ON d."date" = p."date"
ORDER BY d."date";