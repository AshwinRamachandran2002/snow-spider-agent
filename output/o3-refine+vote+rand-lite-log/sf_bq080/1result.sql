WITH contracts AS (
    /* daily new‑contract counts, split by creator type */
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "DAY",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 'EXTERNAL_USER'
            ELSE 'CONTRACT'
        END                                                         AS "CREATOR_TYPE",
        COUNT(*)                                                    AS "CNT"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_TIMESTAMP("block_timestamp" / 1000000) >= '2018-08-30'::TIMESTAMP
      AND TO_TIMESTAMP("block_timestamp" / 1000000) <  '2018-10-01'::TIMESTAMP
    GROUP BY "DAY", "CREATOR_TYPE"
),
all_dates AS (
    /* calendar table for every day 2018‑08‑30 … 2018‑09‑30 */
    SELECT
        DATEADD(day, n, '2018-08-30'::DATE) AS "DAY"
    FROM (
        /* 40 rows are enough to cover the 32‑day span */
        SELECT SEQ4() AS n
        FROM TABLE(GENERATOR(ROWCOUNT => 40))
    )
    WHERE DATEADD(day, n, '2018-08-30'::DATE) <= '2018-09-30'::DATE
),
daily_counts AS (
    /* join calendar with actual counts (missing days -> 0) */
    SELECT
        d."DAY",
        COALESCE(c_ext."CNT", 0) AS "NEW_EXTERNAL_CONTRACTS",
        COALESCE(c_int."CNT", 0) AS "NEW_INTERNAL_CONTRACTS"
    FROM       all_dates d
    LEFT JOIN  contracts c_ext
           ON  d."DAY" = c_ext."DAY"
          AND c_ext."CREATOR_TYPE" = 'EXTERNAL_USER'
    LEFT JOIN  contracts c_int
           ON  d."DAY" = c_int."DAY"
          AND c_int."CREATOR_TYPE" = 'CONTRACT'
),
cumulative AS (
    /* running totals to get cumulative counts */
    SELECT
        "DAY",
        SUM("NEW_EXTERNAL_CONTRACTS") OVER (ORDER BY "DAY") AS "CUM_EXTERNAL_CONTRACTS",
        SUM("NEW_INTERNAL_CONTRACTS") OVER (ORDER BY "DAY") AS "CUM_INTERNAL_CONTRACTS"
    FROM daily_counts
)
SELECT
    "DAY",
    "CUM_EXTERNAL_CONTRACTS",
    "CUM_INTERNAL_CONTRACTS"
FROM cumulative
ORDER BY "DAY";