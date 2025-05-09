WITH
-- 1. All calendar days in the requested range
"dates" AS (
    SELECT
        DATEADD(day, seq4(), TO_DATE('2018-08-30')) AS "dt"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))   -- 32 days (2018‑08‑30 … 2018‑09‑30, inclusive)
),

-- 2. Contract‑creation traces in the period
"creations" AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))          AS "dt",
        CASE WHEN "trace_address" IS NULL THEN 1 ELSE 0 END          AS "ext_user_creation",
        CASE WHEN "trace_address" IS NULL THEN 0 ELSE 1 END          AS "contract_creation"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
            BETWEEN '2018-08-30' AND '2018-09-30'
),

-- 3. Daily totals
"daily_totals" AS (
    SELECT
        "dt",
        SUM("ext_user_creation")    AS "ext_user_cnt",
        SUM("contract_creation")    AS "contract_cnt"
    FROM "creations"
    GROUP BY "dt"
),

-- 4. Merge calendar with daily totals and build cumulative counts
"cumulative" AS (
    SELECT
        d."dt",
        /* ensure missing days are treated as zeros,
           then build strictly non‑decreasing cumulative sums */
        SUM(COALESCE(t."ext_user_cnt", 0))
            OVER (ORDER BY d."dt")  AS "cumulative_ext_user",
        SUM(COALESCE(t."contract_cnt", 0))
            OVER (ORDER BY d."dt")  AS "cumulative_contract"
    FROM "dates" d
    LEFT JOIN "daily_totals" t
           ON d."dt" = t."dt"
)

SELECT
    "dt"                                            AS "date",
    "cumulative_ext_user"                           AS "external_user_created_contracts",
    "cumulative_contract"                           AS "contract_created_contracts"
FROM "cumulative"
ORDER BY "date";