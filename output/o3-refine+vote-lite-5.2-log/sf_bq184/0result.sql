/* ============================================================
   Daily cumulative number of contracts created on Ethereum
   (2017‑01‑01 – 2021‑12‑31) split by creator type
   ============================================================ */

WITH
-- 1. calendar covering every day in the requested period
date_range AS (
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS "date"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)              -- 2017‑01‑01 through 2021‑12‑31 (inclusive)
    )
),

-- 2. daily counts of contract‑creation traces by creator type
daily_creations AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp", 6)) AS "date",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 'externally_owned'
            ELSE 'contract'
        END                                             AS creator_type,
        COUNT(*)                                        AS daily_cnt
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp", 6))
            BETWEEN '2017-01-01'::DATE AND '2021-12-31'::DATE
    GROUP BY 1, 2
),

-- 3. merge calendar with daily counts (fill missing dates with 0)
daily_totals AS (
    SELECT
        d."date",
        COALESCE(SUM(CASE WHEN c.creator_type = 'externally_owned' THEN c.daily_cnt END), 0) AS daily_eoa,
        COALESCE(SUM(CASE WHEN c.creator_type = 'contract'         THEN c.daily_cnt END), 0) AS daily_contract
    FROM date_range d
    LEFT JOIN daily_creations c
           ON d."date" = c."date"
    GROUP BY d."date"
),

-- 4. cumulative sums
cumulative AS (
    SELECT
        "date",
        SUM(daily_eoa)      OVER (ORDER BY "date") AS cumulative_created_by_eoa,
        SUM(daily_contract) OVER (ORDER BY "date") AS cumulative_created_by_contract
    FROM daily_totals
)

-- 5. final result
SELECT
    "date",
    cumulative_created_by_eoa,
    cumulative_created_by_contract
FROM cumulative
ORDER BY "date";