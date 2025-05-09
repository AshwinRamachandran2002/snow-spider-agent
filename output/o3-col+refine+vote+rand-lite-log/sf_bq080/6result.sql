WITH
-- 1. calendar covering every calendar day in the period (32 days inclusive)
date_span AS (
    SELECT
        DATEADD(
            day,
            SEQ4(),                     -- 0 … 31
            TO_DATE('2018-08-30')       -- start date (inclusive)
        ) AS "day"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 32)       -- fixed constant rowcount
    )
),

-- 2. daily counts of contract-creation traces, split by creator type
daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_LTZ("block_timestamp" / 1e6))                AS "day",
        SUM(CASE WHEN "trace_address" IS NULL     THEN 1 ELSE 0 END)      AS "new_eoa",
        SUM(CASE WHEN "trace_address" IS NOT NULL THEN 1 ELSE 0 END)      AS "new_via_contract"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP_LTZ("block_timestamp" / 1e6))
            BETWEEN '2018-08-30' AND '2018-09-30'
    GROUP BY "day"
),

-- 3. join calendar with daily counts, filling gaps with zeros
joined AS (
    SELECT
        c."day",
        COALESCE(d."new_eoa",          0) AS "new_eoa",
        COALESCE(d."new_via_contract", 0) AS "new_via_contract"
    FROM date_span c
    LEFT JOIN daily d
      ON c."day" = d."day"
)

-- 4. cumulative totals
SELECT
    "day",
    SUM("new_eoa")          OVER (ORDER BY "day") AS "cum_eoa",
    SUM("new_via_contract") OVER (ORDER BY "day") AS "cum_via_contract"
FROM joined
ORDER BY "day";