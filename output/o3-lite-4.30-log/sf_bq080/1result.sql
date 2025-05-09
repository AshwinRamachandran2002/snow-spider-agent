WITH date_spine AS (          -- generate every calendar day in the window
    SELECT DATEADD(day, SEQ4(), '2018-08-30') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))     -- 32 days = 30‑Aug‑2018 … 30‑Sep‑2018
),
daily_counts AS (             -- contracts created each day
    SELECT
        CAST(TO_TIMESTAMP("block_timestamp" / 1000000) AS DATE)      AS "date",
        COUNT_IF("trace_address" IS NULL)      AS new_eoa,           -- by EOA
        COUNT_IF("trace_address" IS NOT NULL)  AS new_internal       -- by contract
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  CAST(TO_TIMESTAMP("block_timestamp" / 1000000) AS DATE)
           BETWEEN '2018-08-30' AND '2018-09-30'
    GROUP BY 1
),
filled_days AS (              -- ensure every day is present
    SELECT
        s."date",
        COALESCE(d.new_eoa,      0) AS new_eoa,
        COALESCE(d.new_internal, 0) AS new_internal
    FROM   date_spine s
    LEFT JOIN daily_counts d USING ("date")
)
SELECT
    "date",
    SUM(new_eoa)      OVER (ORDER BY "date") AS cumulative_eoa_contracts,
    SUM(new_internal) OVER (ORDER BY "date") AS cumulative_internal_contracts
FROM   filled_days
ORDER BY "date";