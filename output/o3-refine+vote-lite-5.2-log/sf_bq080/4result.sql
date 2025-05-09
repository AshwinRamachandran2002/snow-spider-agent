WITH date_series AS (   -- list every day in the range (32 days total)
    SELECT DATEADD(day, seq4(), DATE '2018-08-30') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),

daily_counts AS (       -- contracts created per day by creator type
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))                       AS "date",
        SUM(CASE WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 1 END) AS "user_created",
        SUM(CASE WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' THEN 1 END) AS "contract_created"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
              BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
    GROUP BY 1
),

combined AS (           -- ensure every date is present
    SELECT
        ds."date",
        COALESCE(dc."user_created", 0)      AS "user_created",
        COALESCE(dc."contract_created", 0)  AS "contract_created"
    FROM date_series ds
    LEFT JOIN daily_counts dc
           ON dc."date" = ds."date"
)

SELECT
    "date",
    SUM("user_created")     OVER (ORDER BY "date") AS "cumulative_user_created_contracts",
    SUM("contract_created") OVER (ORDER BY "date") AS "cumulative_contract_created_contracts"
FROM   combined
ORDER  BY "date";