/* --------------------------------------------------------------
Daily cumulative counts of Ethereum smart-contract creations
  • cumulative_external_contracts : created directly by EOAs
    (TRACE_ADDRESS IS NULL)
  • cumulative_internal_contracts : created by other contracts
    (TRACE_ADDRESS IS NOT NULL)

Period covered : 2017-01-01  →  2021-12-31 (inclusive)
---------------------------------------------------------------*/
WITH
/* 1. Calendar covering every day in the range (5 years = 1 826 days) */
date_range AS (
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))  -- 2017-01-01 .. 2021-12-31
),

/* 2. Contract-creation traces classified by creator type */
contract_creations AS (
    SELECT
        CAST(
            DATE_TRUNC(
                'DAY',
                TO_TIMESTAMP("block_timestamp" / 1000000)
            ) AS DATE
        )                                                   AS dt,
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = ''
                 THEN 'external'
            ELSE 'internal'
        END                                                 AS category
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  TO_TIMESTAMP("block_timestamp" / 1000000)
              BETWEEN '2017-01-01' AND '2021-12-31 23:59:59'
),

/* 3. Daily counts per category */
daily_counts AS (
    SELECT
        dt,
        COUNT_IF(category = 'external')  AS external_cnt,
        COUNT_IF(category = 'internal')  AS internal_cnt
    FROM   contract_creations
    GROUP  BY dt
),

/* 4. Ensure every day is present; fill missing with zeros */
all_days AS (
    SELECT
        d.dt,
        COALESCE(dc.external_cnt, 0) AS external_cnt,
        COALESCE(dc.internal_cnt, 0) AS internal_cnt
    FROM   date_range d
    LEFT   JOIN daily_counts dc
           ON d.dt = dc.dt
)

/* 5. Cumulative, monotonically increasing totals */
SELECT
    dt                                                 AS "date",
    SUM(external_cnt) OVER (ORDER BY dt)
        AS cumulative_external_contracts,
    SUM(internal_cnt) OVER (ORDER BY dt)
        AS cumulative_internal_contracts
FROM   all_days
ORDER  BY dt;