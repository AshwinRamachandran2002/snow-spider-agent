/*  Daily cumulative count of Ethereum contracts created
    ‑ external address  : "trace_address" IS NULL / '' / '0'
    ‑ contract address  : any other non‑NULL "trace_address"
    Date range          : 2017‑01‑01 … 2021‑12‑31 (inclusive)
*/

WITH date_series AS (                       -- one row per calendar day
    SELECT DATEADD(day, SEQ4(), DATE '2017-01-01') AS "date"
    FROM   TABLE(GENERATOR(ROWCOUNT => 1826))      -- 2017‑01‑01 → 2021‑12‑31  = 1 826 days
),
daily_counts AS (                            -- contract creations per day
    SELECT
        TO_DATE( TO_TIMESTAMP( "block_timestamp" / 1000000 ) )                 AS "date",
        SUM( CASE WHEN "trace_address" IS NULL
                       OR "trace_address" IN ('', '0')
                  THEN 1 ELSE 0 END )                                          AS "external_creations",
        SUM( CASE WHEN "trace_address" IS NOT NULL
                       AND "trace_address" NOT IN ('', '0')
                  THEN 1 ELSE 0 END )                                          AS "contract_creations"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  TO_DATE( TO_TIMESTAMP( "block_timestamp" / 1000000 ) )
             BETWEEN DATE '2017-01-01' AND DATE '2021-12-31'
    GROUP BY 1
),
combined AS (                               -- include every calendar day
    SELECT
        ds."date",
        COALESCE(dc."external_creations", 0)  AS "external_creations",
        COALESCE(dc."contract_creations", 0)  AS "contract_creations"
    FROM   date_series ds
    LEFT  JOIN daily_counts dc
           ON ds."date" = dc."date"
),
cumulative AS (                             -- running totals
    SELECT
        "date",
        SUM("external_creations")  OVER (ORDER BY "date")
            AS "cumulative_external_creations",
        SUM("contract_creations")  OVER (ORDER BY "date")
            AS "cumulative_contract_creations"
    FROM   combined
)
SELECT
    "date",
    "cumulative_external_creations",
    "cumulative_contract_creations"
FROM   cumulative
ORDER BY "date";