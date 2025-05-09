WITH calendar AS (   -- 32 calendar days from 2018-08-30 to 2018-09-30 (inclusive)
    SELECT DATEADD(day, SEQ4(), '2018-08-30'::date) AS "date"
    FROM  TABLE(GENERATOR(ROWCOUNT => 32))
), 
creations AS (       -- contract-creation traces inside the window
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))                   AS "date",
        CASE WHEN "trace_address" IS NULL OR "trace_address" = ''
             THEN 'external' ELSE 'contract' END                             AS "creator_type"
    FROM  CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE LOWER("trace_type") = 'create'
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
          BETWEEN '2018-08-30'::date AND '2018-09-30'::date
), 
daily_counts AS (     -- daily new contracts for each creator type
    SELECT
        "date",
        COUNT_IF("creator_type" = 'external')  AS "external_daily",
        COUNT_IF("creator_type" = 'contract')  AS "contract_daily"
    FROM  creations
    GROUP BY "date"
), 
all_days AS (         -- ensure every date is present
    SELECT
        c."date",
        COALESCE(d."external_daily", 0) AS "external_daily",
        COALESCE(d."contract_daily", 0) AS "contract_daily"
    FROM  calendar c
    LEFT JOIN daily_counts d USING ("date")
)
SELECT
    "date",
    SUM("external_daily")  OVER (ORDER BY "date") AS "external_cumulative",
    SUM("contract_daily")  OVER (ORDER BY "date") AS "contract_cumulative"
FROM all_days
ORDER BY "date";