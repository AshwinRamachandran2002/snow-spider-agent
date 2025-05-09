WITH
-- calendar of every day from 2017‑01‑01 to 2021‑12‑31 (inclusive)
dates AS (
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS "dt"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))   -- 1‑Jan‑2017 .. 31‑Dec‑2021
),

-- daily counts of contract‑creation traces split by creator type
creations AS (
    SELECT
        TO_DATE(CONVERT_TIMEZONE('UTC',
                 TO_TIMESTAMP("block_timestamp" / 1e6)))  AS "dt",
        CASE
            WHEN "trace_address" IS NULL THEN 'external'
            ELSE 'contract'
        END                                             AS "creator_type",
        COUNT(*)                                        AS "cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(CONVERT_TIMEZONE('UTC',
                 TO_TIMESTAMP("block_timestamp" / 1e6)))
          BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY 1, 2
),

-- pivot to one row per date with separate columns
daily AS (
    SELECT
        d."dt",
        COALESCE(MAX(CASE WHEN c."creator_type" = 'external' THEN c."cnt" END), 0)
            AS "external_creations",
        COALESCE(MAX(CASE WHEN c."creator_type" = 'contract' THEN c."cnt" END), 0)
            AS "contract_creations"
    FROM dates d
    LEFT JOIN creations c
           ON d."dt" = c."dt"
    GROUP BY d."dt"
),

-- cumulative totals
cumulative AS (
    SELECT
        "dt",
        SUM("external_creations")  OVER (ORDER BY "dt") AS "cumulative_external",
        SUM("contract_creations")  OVER (ORDER BY "dt") AS "cumulative_contract"
    FROM daily
)

SELECT *
FROM cumulative
ORDER BY "dt";