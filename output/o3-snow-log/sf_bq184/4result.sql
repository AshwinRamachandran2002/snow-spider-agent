/*  Daily cumulative counts of contracts created by
    – external accounts   : trace_address IS NULL / ''
    – other smart contracts: trace_address IS NOT NULL
    for every calendar date from 2017-01-01 through 2021-12-31            */

WITH
/* ----------------------------------------------------------------- *
| 1. Calendar table – one row per day in the requested period        |
|    2017-01-01 .. 2021-12-31  (inclusive → 1 826 days)               |
* ------------------------------------------------------------------ */
date_range AS (
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01')  AS dt
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)         -- 365+365+365+366+365
    )
),

/* ----------------------------------------------------------------- *
| 2. All CREATE-type traces (Ethereum + Ethereum Classic)            |
* ------------------------------------------------------------------ */
creations AS (
    SELECT
        /* convert micro-second epoch to DATE (UTC)                  */
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)
        )::DATE                                  AS dt ,

        CASE
            WHEN "trace_address" IS NULL
              OR "trace_address" = ''            THEN 'eoa'
            ELSE 'contract'
        END                                      AS creator_type ,

        COUNT(*)                                 AS cnt
    FROM (
        SELECT "block_timestamp","trace_address","trace_type"
        FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
        UNION ALL
        SELECT "block_timestamp","trace_address","trace_type"
        FROM   CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    )
    WHERE "trace_type" = 'create'
    GROUP BY 1,2
),

/* ----------------------------------------------------------------- *
| 3. Join calendar with daily counts (fill gaps with zeros)          |
* ------------------------------------------------------------------ */
daily AS (
    SELECT
        d.dt ,

        COALESCE(SUM(CASE WHEN c.creator_type = 'eoa'      THEN c.cnt END),0)
            AS eoa_creations ,

        COALESCE(SUM(CASE WHEN c.creator_type = 'contract' THEN c.cnt END),0)
            AS contract_creations
    FROM   date_range d
    LEFT   JOIN creations c
           ON d.dt = c.dt
    GROUP  BY d.dt
),

/* ----------------------------------------------------------------- *
| 4. Cumulative totals                                               |
* ------------------------------------------------------------------ */
cumulative AS (
    SELECT
        dt                                          AS "DATE"                       ,
        SUM(eoa_creations)
          OVER (ORDER BY dt)                       AS cumulative_eoa_creations     ,
        SUM(contract_creations)
          OVER (ORDER BY dt)                       AS cumulative_contract_creations
    FROM   daily
)

/* ----------------------------------------------------------------- *
| 5. Final result                                                    |
* ------------------------------------------------------------------ */
SELECT *
FROM   cumulative
ORDER  BY "DATE";