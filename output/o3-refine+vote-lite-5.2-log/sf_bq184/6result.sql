/* Daily cumulative contract‑creations (EOA vs contract creators)
   on Ethereum + Ethereum‑Classic, 2017‑01‑01 … 2021‑12‑31          */

WITH all_creations AS (   /* all contract‑creation traces */
    SELECT
        CAST(DATE_TRUNC('day',
               TO_TIMESTAMP("block_timestamp" / 1e6)) AS DATE)              AS "date",
        CASE WHEN "trace_address" IS NULL OR "trace_address" = ''
             THEN 'EXTERNAL' ELSE 'CONTRACT' END                           AS "creator_type"
    FROM  CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'

    UNION ALL

    SELECT
        CAST(DATE_TRUNC('day',
               TO_TIMESTAMP("block_timestamp" / 1e6)) AS DATE)              AS "date",
        CASE WHEN "trace_address" IS NULL OR "trace_address" = ''
             THEN 'EXTERNAL' ELSE 'CONTRACT' END                           AS "creator_type"
    FROM  CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    WHERE "trace_type" = 'create'
),

daily_counts AS (         /* contracts created per day, by creator type */
    SELECT
        "date",
        COUNT_IF("creator_type" = 'EXTERNAL')  AS "external_cnt",
        COUNT_IF("creator_type" = 'CONTRACT')  AS "contract_cnt"
    FROM   all_creations
    GROUP  BY "date"
),

calendar AS (             /* every day in range (constant 1 826 rows) */
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS "date"
    FROM   TABLE(GENERATOR(ROWCOUNT => 1826))     -- 2017‑01‑01 .. 2021‑12‑31
),

daily_full AS (           /* ensure every day has a row */
    SELECT
        c."date",
        COALESCE(d."external_cnt", 0)  AS "external_cnt",
        COALESCE(d."contract_cnt", 0)  AS "contract_cnt"
    FROM   calendar c
    LEFT   JOIN daily_counts d USING ("date")
),

cumulative AS (           /* running totals */
    SELECT
        "date",
        SUM("external_cnt") OVER (ORDER BY "date")  AS "cumulative_external_contracts",
        SUM("contract_cnt") OVER (ORDER BY "date")  AS "cumulative_contract_created_contracts"
    FROM   daily_full
)

SELECT *
FROM   cumulative
ORDER  BY "date";