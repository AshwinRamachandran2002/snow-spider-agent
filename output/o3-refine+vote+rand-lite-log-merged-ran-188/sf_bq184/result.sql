WITH date_series AS (   /* every day from 2017‑01‑01 to 2021‑12‑31 (inclusive = 1 826 days) */
    SELECT
        DATEADD(
            'day',
            SEQ4(),                     -- 0 … 1 825
            TO_DATE('2017-01-01')
        ) AS "date"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)     -- fixed constant
    )
),
raw_creations AS (      /* contract‑creation traces */
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                          AS "date",
        IFF("trace_address" IS NULL, 1, 0)                                      AS "external_creation",
        IFF("trace_address" IS NOT NULL, 1, 0)                                  AS "contract_creation"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE LOWER("trace_type") = 'create'
      AND "block_timestamp" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))
            BETWEEN '2017-01-01' AND '2021-12-31'

    UNION ALL

    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                          AS "date",
        IFF("trace_address" IS NULL, 1, 0)                                      AS "external_creation",
        IFF("trace_address" IS NOT NULL, 1, 0)                                  AS "contract_creation"
    FROM "CRYPTO"."CRYPTO_ETHEREUM_CLASSIC"."TRACES"
    WHERE LOWER("trace_type") = 'create'
      AND "block_timestamp" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))
            BETWEEN '2017-01-01' AND '2021-12-31'
),
daily_counts AS (        /* per‑day sums */
    SELECT
        "date",
        SUM("external_creation")  AS "ext_cnt",
        SUM("contract_creation")  AS "ctr_cnt"
    FROM raw_creations
    GROUP BY "date"
),
daily_full AS (          /* make every date present */
    SELECT
        ds."date",
        COALESCE(dc."ext_cnt", 0) AS "ext_cnt",
        COALESCE(dc."ctr_cnt", 0) AS "ctr_cnt"
    FROM date_series ds
    LEFT JOIN daily_counts dc
           ON ds."date" = dc."date"
)
SELECT
    "date",
    SUM("ext_cnt") OVER (
        ORDER BY "date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "cumulative_external_creations",
    SUM("ctr_cnt") OVER (
        ORDER BY "date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "cumulative_contract_creations"
FROM daily_full
ORDER BY "date";