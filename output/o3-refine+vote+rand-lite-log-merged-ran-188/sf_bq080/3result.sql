WITH date_span AS (   -- 32 consecutive days 2018‑08‑30 … 2018‑09‑30
    SELECT 
        DATEADD(day, seq4(), '2018-08-30') AS "DATE"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
daily_new AS (        -- contracts created each day by origin
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp"/1000000))                                    AS "DATE",
        CASE 
            WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 'EXTERNAL'
            ELSE 'INTERNAL'
        END                                                                                 AS "ORIGIN",
        COUNT(*)                                                                            AS "NEW_CNT"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP("block_timestamp"/1000000))
            BETWEEN '2018-08-30' AND '2018-09-30'
    GROUP BY 1,2
),
daily_pivot AS (      -- pivot to one row per day
    SELECT
        "DATE",
        SUM(CASE WHEN "ORIGIN" = 'EXTERNAL' THEN "NEW_CNT" END)  AS "NEW_EXTERNAL",
        SUM(CASE WHEN "ORIGIN" = 'INTERNAL' THEN "NEW_CNT" END)  AS "NEW_INTERNAL"
    FROM daily_new
    GROUP BY 1
),
daily_full AS (       -- ensure every date is present, fill zeros
    SELECT
        d."DATE",
        COALESCE(p."NEW_EXTERNAL",0) AS "NEW_EXTERNAL",
        COALESCE(p."NEW_INTERNAL",0) AS "NEW_INTERNAL"
    FROM date_span d
    LEFT JOIN daily_pivot p USING ("DATE")
)
SELECT
    "DATE",
    SUM("NEW_EXTERNAL") OVER (ORDER BY "DATE") AS "CUM_EXTERNAL_CONTRACTS",
    SUM("NEW_INTERNAL") OVER (ORDER BY "DATE") AS "CUM_INTERNAL_CONTRACTS"
FROM daily_full
ORDER BY "DATE";