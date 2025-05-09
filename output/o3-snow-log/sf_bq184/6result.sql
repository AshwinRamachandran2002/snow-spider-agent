/*  Daily cumulative number of contracts created
    – “cumulative_eoa_creations”      : creations whose trace_address IS NULL  (initiated by EOAs)
    – “cumulative_contract_creations” : creations whose trace_address IS NOT NULL (initiated by contracts)
    Full calendar coverage 2017-01-01 … 2021-12-31 (inclusive)                */

WITH date_range AS (          -- one row per calendar day (1826 days inclusive)
    SELECT
        DATEADD(day, SEQ4(), DATE '2017-01-01') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))      -- 365+365+365+366+365 = 1 826
),
daily_creations AS (          -- count contract-creation traces per day
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000))::DATE AS "date",
        SUM(CASE WHEN "trace_address" IS NULL
                  OR TRIM("trace_address") = ''  THEN 1 ELSE 0 END) AS "eoa_cnt",
        SUM(CASE WHEN "trace_address" IS NOT NULL
                  AND TRIM("trace_address") <> '' THEN 1 ELSE 0 END) AS "contract_cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000))
          BETWEEN DATE '2017-01-01' AND DATE '2021-12-31'
    GROUP BY 1
),
all_days AS (                 -- ensure every day appears
    SELECT
        dr."date",
        COALESCE(dc."eoa_cnt",      0) AS "eoa_cnt",
        COALESCE(dc."contract_cnt", 0) AS "contract_cnt"
    FROM date_range dr
    LEFT JOIN daily_creations dc
           ON dr."date" = dc."date"
),
cumulative AS (               -- running totals
    SELECT
        "date",
        SUM("eoa_cnt")      OVER (ORDER BY "date") AS "cumulative_eoa_creations",
        SUM("contract_cnt") OVER (ORDER BY "date") AS "cumulative_contract_creations"
    FROM all_days
)
SELECT *
FROM   cumulative
ORDER  BY "date";