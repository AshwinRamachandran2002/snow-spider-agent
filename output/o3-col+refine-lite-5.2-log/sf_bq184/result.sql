/* ----------------------------------------------------------------------
   Daily cumulative smart‑contract creations (EOA vs. internal)
   for every calendar day 2017‑01‑01 … 2021‑12‑31
---------------------------------------------------------------------- */
WITH raw_dates AS (     -- produce 2 000 consecutive days from 2017‑01‑01
    SELECT DATEADD(day, SEQ4(), DATE '2017-01-01') AS "creation_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
),
date_series AS (        -- keep only dates within requested window
    SELECT "creation_date"
    FROM   raw_dates
    WHERE  "creation_date" <= DATE '2021-12-31'
),

daily_creations AS (    -- count contract‑creation traces per day
    SELECT
        TO_DATE(
            CONVERT_TIMEZONE(
                'UTC','UTC',
                TO_TIMESTAMP("block_timestamp" / 1000000)
            )
        )                                             AS "creation_date",
        SUM(
            CASE
                WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 1
                ELSE 0
            END
        )                                             AS "eoa_creations",
        SUM(
            CASE
                WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' THEN 1
                ELSE 0
            END
        )                                             AS "internal_creations"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "block_timestamp"
            BETWEEN 1483228800000000  /* 2017‑01‑01 00:00:00 UTC */
                AND 1640995199000000  /* 2021‑12‑31 23:59:59 UTC */
    GROUP BY "creation_date"
),

daily_full AS (         -- ensure every day appears, filling gaps with zero
    SELECT
        ds."creation_date",
        COALESCE(dc."eoa_creations",      0) AS "daily_eoa",
        COALESCE(dc."internal_creations", 0) AS "daily_internal"
    FROM date_series ds
    LEFT JOIN daily_creations dc
           ON dc."creation_date" = ds."creation_date"
)

SELECT
    "creation_date",
    SUM("daily_eoa")      OVER (ORDER BY "creation_date")
        AS "cum_eoa_creations",
    SUM("daily_internal") OVER (ORDER BY "creation_date")
        AS "cum_internal_creations"
FROM daily_full
ORDER BY "creation_date";