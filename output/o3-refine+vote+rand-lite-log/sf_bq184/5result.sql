WITH all_days AS (   -- every calendar day in the requested range
    SELECT 
        DATEADD(day, SEQ4(), '2017-01-01') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))             -- 2017‑01‑01 … 2021‑12‑31
),                                                         
raw_creates AS (   -- contract‑creation traces from Ethereum + ETC
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "date",
        CASE
            WHEN "trace_address" IS NULL THEN 'external'  -- created by EOA
            ELSE 'contract'                               -- created by contract
        END                                               AS "category",
        "to_address"                                      AS "new_contract"
    FROM (
        SELECT * FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
        UNION ALL
        SELECT * FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    )
    WHERE LOWER("trace_type") LIKE 'create%'              -- CREATE / CREATE2
      AND "block_timestamp" BETWEEN 1483228800000000      -- 2017‑01‑01
                               AND   1640995199000000     -- 2021‑12‑31 23:59:59
),                     
daily_creates AS (   -- daily unique contract counts per category
    SELECT
        "date",
        "category",
        COUNT(DISTINCT "new_contract") AS "cnt"
    FROM raw_creates
    GROUP BY "date", "category"
),                     
days_with_counts AS (   -- ensure every day exists, fill missing with zeros
    SELECT
        d."date",
        COALESCE(SUM(CASE WHEN c."category" = 'external'  THEN c."cnt" END), 0)
            AS "external_creations",
        COALESCE(SUM(CASE WHEN c."category" = 'contract' THEN c."cnt" END), 0)
            AS "contract_creations"
    FROM all_days d
    LEFT JOIN daily_creates c
           ON d."date" = c."date"
    GROUP BY d."date"
),                     
cumulative AS (        -- running cumulative totals
    SELECT
        "date",
        SUM("external_creations")  OVER (ORDER BY "date")
            AS "cumulative_external_creations",
        SUM("contract_creations")  OVER (ORDER BY "date")
            AS "cumulative_contract_creations"
    FROM days_with_counts
)
SELECT *
FROM   cumulative
ORDER  BY "date";