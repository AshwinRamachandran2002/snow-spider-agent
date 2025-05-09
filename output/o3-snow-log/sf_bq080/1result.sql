WITH date_series AS (           -- 32 days between 30-Aug-2018 and 30-Sep-2018 (inclusive)
    SELECT
        DATEADD(day, SEQ4(), '2018-08-30') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),

-- every successful contract-creation trace within the period
creations AS (
    SELECT
        DATE_TRUNC('DAY', TO_TIMESTAMP("block_timestamp" / 1e6))::DATE        AS "date",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" IN ('', '0') THEN 1
            ELSE 0
        END                                                                    AS "external_created",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" IN ('', '0') THEN 0
            ELSE 1
        END                                                                    AS "internal_created"
    FROM  CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND DATE_TRUNC('DAY', TO_TIMESTAMP("block_timestamp" / 1e6))
          BETWEEN '2018-08-30' AND '2018-09-30'
),

-- daily totals
daily_counts AS (
    SELECT
        "date",
        SUM("external_created") AS "external_created",
        SUM("internal_created") AS "internal_created"
    FROM creations
    GROUP BY "date"
),

-- ensure every calendar date is present
daily_with_zeros AS (
    SELECT
        ds."date",
        COALESCE(dc."external_created", 0) AS "external_created",
        COALESCE(dc."internal_created", 0) AS "internal_created"
    FROM date_series ds
    LEFT JOIN daily_counts dc
           ON ds."date" = dc."date"
)

-- cumulative (non-decreasing) totals
SELECT
    "date",
    SUM("external_created") OVER (ORDER BY "date") AS "cumulative_external_contracts",
    SUM("internal_created") OVER (ORDER BY "date") AS "cumulative_internal_contracts"
FROM daily_with_zeros
ORDER BY "date";