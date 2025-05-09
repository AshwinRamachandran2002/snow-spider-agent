/*  Daily cumulative counts of Ethereum contract creations
    – “EOA_CREATIONS”  : contracts whose creating trace has trace_address IS NULL
    – “CONTRACT_CREATIONS” : contracts created by another contract (trace_address IS NOT NULL)
    Calendar covers every day 2017-01-01 … 2021-12-31 (inclusive) so the
    cumulative totals are monotonic without gaps.
*/
WITH calendar AS (          -- full calendar for the required period
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01') AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
    WHERE DATEADD(day, SEQ4(), '2017-01-01') <= '2021-12-31'
),
daily_counts AS (           -- per-day new-contract counts from traces
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)                   AS d,
        SUM(CASE WHEN "trace_address" IS NULL      THEN 1 ELSE 0 END)::INTEGER        AS eoa_cnt,
        SUM(CASE WHEN "trace_address" IS NOT NULL  THEN 1 ELSE 0 END)::INTEGER        AS ctr_cnt
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)
           BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY d
),
merged AS (                 -- calendar left-joined to daily counts, zeros where missing
    SELECT
        c.d,
        COALESCE(d.eoa_cnt, 0) AS eoa_cnt,
        COALESCE(d.ctr_cnt, 0) AS ctr_cnt
    FROM   calendar c
    LEFT JOIN daily_counts d
           ON c.d = d.d
)
SELECT
    d                                           AS "date",
    SUM(eoa_cnt) OVER (ORDER BY d)  AS "cumulative_eoa_creations",
    SUM(ctr_cnt) OVER (ORDER BY d)  AS "cumulative_contract_creations"
FROM   merged
ORDER BY d;