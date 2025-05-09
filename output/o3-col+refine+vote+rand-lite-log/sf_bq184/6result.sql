/*  Daily cumulative smart-contract creations on Ethereum
    (2017-01-01 → 2021-12-31) split by creator type                   */

WITH
-- 1. Calendar covering every day in the required range
"dates" AS (
    SELECT "date"
    FROM (
        SELECT DATEADD(day, SEQ4(), TO_DATE('2017-01-01')) AS "date"
        FROM TABLE(GENERATOR(ROWCOUNT => 1826))    -- 2017-01-01 … 2021-12-31  (inclusive)
    )
    WHERE "date" <= '2021-12-31'
),

-- 2. Daily counts of CREATE traces, separated by creator type
"daily_creates" AS (
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)              AS "date",
        SUM(CASE WHEN "trace_address" IS NULL     THEN 1 ELSE 0 END)             AS "eoa_created",
        SUM(CASE WHEN "trace_address" IS NOT NULL THEN 1 ELSE 0 END)             AS "contract_created"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)
            BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY 1
),

-- 3. Combine calendar with counts, filling missing days with zeros
"series_with_counts" AS (
    SELECT
        d."date",
        COALESCE(c."eoa_created",      0) AS "eoa_created",
        COALESCE(c."contract_created", 0) AS "contract_created"
    FROM "dates" d
    LEFT JOIN "daily_creates" c
           ON d."date" = c."date"
)

-- 4. Calculate cumulative totals
SELECT
    "date",
    SUM("eoa_created")      OVER (ORDER BY "date") AS "cumulative_eoa_created",
    SUM("contract_created") OVER (ORDER BY "date") AS "cumulative_contract_created"
FROM "series_with_counts"
ORDER BY "date";